"""This module holds high-level functions for opening and saving data.

"""


import os
import gcsfs
import pandas as pd

from functools import singledispatch
from pathlib import Path

from sqlalchemy.sql.expression import Executable, ClauseElement
from sqlalchemy.ext.compiler import compiles
from sqlalchemy import create_engine, Table, MetaData, sql


# Config related --------------------------------------------------------------


def is_development():
    options = {"development", "cal-itp-data-infra"}

    if os.environ["AIRFLOW_ENV"] not in options:
        raise ValueError("AIRFLOW_ENV variable must be one of %s" % options)

    return os.environ["AIRFLOW_ENV"] == "development"


def get_bucket():
    # TODO: can probably pull some of these behaviors into a config class
    return os.environ["AIRFLOW_VAR_EXTRACT_BUCKET"]


def get_project_id():
    return "cal-itp-data-infra"


def format_table_name(name, is_staging=False, full_name=False):
    dataset, table_name = name.split(".")
    staging = "__staging" if is_staging else ""
    test_prefix = "test_" if is_development() else ""

    project_id = get_project_id() + "." if full_name else ""
    # e.g. test_gtfs_schedule__staging.agency

    return f"{project_id}{test_prefix}{dataset}.{table_name}{staging}"


# SQL related -----------------------------------------------------------------
# TODO: move into a submodule? (db)


class CreateTableAs(Executable, ClauseElement):
    def __init__(
        self, name, select, replace=False, if_not_exists=False, partition_by=None
    ):
        self.name = name
        self.select = select
        self.replace = replace
        self.if_not_exists = if_not_exists
        self.partition_by = partition_by


@compiles(CreateTableAs)
def visit_insert_from_select(element, compiler, **kw):
    name = compiler.dialect.identifier_preparer.quote(element.name)
    select = compiler.process(element.select, **kw)
    or_replace = " OR REPLACE" if element.replace else ""
    if_not_exists = " IF NOT EXISTS" if element.if_not_exists else ""

    # TODO: visit partition by clause
    partition_by = (
        f" PARTITION BY {element.partition_by}" if element.partition_by else ""
    )

    return f"""
        CREATE{or_replace} TABLE{if_not_exists} {name}
        {partition_by}
        AS {select}
        """


def get_engine():
    return create_engine(
        "bigquery://cal-itp-data-infra/?maximum_bytes_billed=5000000000"
    )


def get_table(table_name, as_df=False):
    engine = get_engine()
    src_table = format_table_name(table_name)

    table = Table(src_table, MetaData(bind=engine), autoload=True)

    if as_df:
        return pd.read_sql_query(table.select(), engine)

    return table


@singledispatch
def write_table(
    sql_stmt,
    table_name,
    engine=None,
    replace=True,
    simplify=True,
    verbose=False,
    if_not_exists=False,
    partition_by=None,
):
    if engine is None:
        engine = get_engine()

    if not isinstance(sql_stmt, sql.ClauseElement):
        sql_stmt = sql.text(sql_stmt)

    create_tbl = CreateTableAs(
        format_table_name(table_name),
        sql_stmt,
        replace=replace,
        if_not_exists=if_not_exists,
        partition_by=partition_by,
    )

    compiled = create_tbl.compile(
        dialect=engine.dialect,
        # binding literals substitutes in parameters, easier to read
        compile_kwargs={"literal_binds": True},
    )

    if verbose:
        print(compiled)

    return engine.execute(compiled)


@write_table.register(pd.DataFrame)
def _write_table_df(sql_stmt, table_name, engine=None, replace=True):
    if_exists = "replace" if replace else "fail"
    return sql_stmt.to_gbq(
        format_table_name(table_name), project_id=get_project_id(), if_exists=if_exists
    )


def query_yaml(fname, write_as=None, replace=False, dry_run=False):
    import yaml
    from jinja2 import Environment, select_autoescape

    config = yaml.safe_load(open(fname))

    sql_template_raw = config["sql"]
    env = Environment(autoescape=select_autoescape())
    env.filters = {**env.filters, **user_defined_filters}

    template = env.from_string(sql_template_raw)

    sql_code = template.render({**user_defined_macros})

    if dry_run:
        print(sql_code)
    elif write_as is not None:
        return write_table(sql_code, write_as, replace=replace)
    else:
        engine = get_engine()
        return engine.execute(sql_code)


def to_snakecase(df):
    """Convert DataFrame column names to snakecase.

    Note that this function also strips some non-ascii charactures, such as '"'.
    """

    return df.rename(
        columns=lambda s: s.lower()
        .replace(" ", "_")
        .replace("&", "_")
        .replace("(", "_")
        .replace(")", "_")
        .replace(".", "_")
        .replace("-", "_")
        .replace("/", "_")
        .replace('"', "")
        .replace("'", "")
    ).rename(columns=lambda s: "_%s" % s if s[0].isdigit() else s)


def sql_patch_comments(table_name, field_comments, bq_client=None):
    """Patch an existing table with new column descriptions."""

    if bq_client is None:
        from google.cloud import bigquery

        bq_client = bigquery.Client()

    tbl = bq_client.get_table(table_name)
    old_schema = tbl.schema

    # make a copy of old schema, then
    new_schema = []
    for col_entry in old_schema:
        d_entry = col_entry.to_api_repr()
        comment = field_comments.get(d_entry["name"])

        if comment:
            # convert entry to dict, change description field, then recreate
            d_entry["description"] = comment

        # fine to keep as dict, since updating table.schema can handle
        new_schema.append(d_entry)

    tbl.schema = new_schema
    bq_client.update_table(tbl, ["schema"])


# Bucket related --------------------------------------------------------------


def pipe_file_name(path):
    """Returns absolute path for a file in the pipeline (e.g. the data folder).

    """

    # For now, we just get the path relative to the directory holding the
    # DAGs folder. For some reason, gcp doesn't expose the same variable
    # for this folder, so need to handle differently on dev.
    if is_development():
        root = Path(os.environ["AIRFLOW__CORE__DAGS_FOLDER"]).parent
    else:
        root = Path(os.environ["DAGS_FOLDER"]).parent

    return str(root / path)


def get_fs(gcs_project="cal-itp-data-infra"):
    if is_development():
        return gcsfs.GCSFileSystem(project=gcs_project, token="google_default")
    else:
        return gcsfs.GCSFileSystem(project=gcs_project, token="cloud")


def save_to_gcfs(
    src_path,
    dst_path,
    gcs_project="cal-itp-data-infra",
    bucket=None,
    use_pipe=False,
    verbose=True,
    **kwargs,
):
    """Convenience function for saving files from disk to google cloud storage.

    Arguments:
        src_path: path to file being saved.
        dst_path: path to bucket subdirectory (e.g. "path/to/dir").
    """

    bucket = get_bucket() if bucket is None else bucket

    full_dst_path = bucket + "/" + str(dst_path)

    fs = get_fs(gcs_project)

    if verbose:
        print("Saving to:", full_dst_path)

    if not use_pipe:
        fs.put(str(src_path), full_dst_path, **kwargs)
    else:
        fs.pipe(str(full_dst_path), src_path, **kwargs)

    return full_dst_path


def read_gcfs(
    src_path, dst_path=None, gcs_project="cal-itp-data-infra", bucket=None, verbose=True
):
    """
    Arguments:
        src_path: path to file being read from google cloud.
        dst_path: optional path to save file directly on disk.
    """

    bucket = get_bucket() if bucket is None else bucket

    fs = get_fs(gcs_project)

    full_src_path = bucket + "/" + str(src_path)

    if verbose:
        print(f"Reading file: {full_src_path}")

    if dst_path is None:
        return fs.open(full_src_path)
    else:
        # TODO: in this case, dump directly to disk, rather opening
        raise NotImplementedError()

    return full_src_path


# Macros ----

user_defined_macros = dict(
    get_project_id=get_project_id,
    get_bucket=get_bucket,
    THE_FUTURE=lambda: 'DATE("2099-01-01")',
)

user_defined_filters = dict(
    table=lambda x: format_table_name(x, is_staging=False, full_name=True),
    quote=lambda s: '"%s"' % s,
)
