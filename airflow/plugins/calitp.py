"""This module holds high-level functions for opening and saving data.

"""


import os
import gcsfs

from pathlib import Path

from sqlalchemy.sql.expression import Executable, ClauseElement
from sqlalchemy.ext.compiler import compiles
from sqlalchemy import create_engine, Table, MetaData, sql

# Manually register pybigquery for now (until it updates on pypi) -------------
# note that this is equivalent to specifying an entrypoint for sqlalchemy

from sqlalchemy.dialects import registry

registry.register("bigquery", "pybigquery.sqlalchemy_bigquery", "BigQueryDialect")


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
    def __init__(self, name, select, replace=False):
        self.name = name
        self.select = select
        self.replace = replace


@compiles(CreateTableAs)
def visit_insert_from_select(element, compiler, **kw):
    name = compiler.dialect.identifier_preparer.quote(element.name)
    select = compiler.process(element.select, **kw)
    or_replace = " OR REPLACE" if element.replace else ""

    return f"CREATE{or_replace} TABLE {name} AS {select}"


def get_engine():
    return create_engine("bigquery://cal-itp-data-infra")


def get_table(table_name, as_df=False):
    engine = get_engine()
    src_table = format_table_name(table_name)

    table = Table(src_table, MetaData(bind=engine), autoload=True)

    if as_df:
        import pandas

        return pandas.read_sql_query(table.select(), engine)

    return table


def write_table(
    sql_stmt, table_name, engine=None, replace=True, simplify=True, verbose=False
):
    if engine is None:
        engine = get_engine()

    if not isinstance(sql_stmt, sql.ClauseElement):
        sql_stmt = sql.text(sql_stmt)

    create_tbl = CreateTableAs(format_table_name(table_name), sql_stmt, replace=replace)

    compiled = create_tbl.compile(
        dialect=engine.dialect,
        # binding literals substitutes in parameters, easier to read
        compile_kwargs={"literal_binds": True},
    )

    if verbose:
        print(compiled)

    return engine.execute(compiled)


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

user_defined_macros = dict(get_project_id=get_project_id, get_bucket=get_bucket)

user_defined_filters = dict(
    table=lambda x: format_table_name(x, is_staging=False, full_name=True),
    quote=lambda s: '"%s"' % s,
)
