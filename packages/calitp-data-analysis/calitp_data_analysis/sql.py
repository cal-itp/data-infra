import os
from functools import singledispatch

import pandas as pd
import yaml
from calitp_data.config import format_table_name, get_project_id, require_pipeline
from calitp_data.templates import user_defined_filters, user_defined_macros
from jinja2 import Environment
from sqlalchemy import MetaData, Table, create_engine, sql
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.sql.expression import ClauseElement, Executable

CALITP_BQ_MAX_BYTES = os.environ.get("CALITP_BQ_MAX_BYTES", 5_000_000_000)
CALITP_BQ_LOCATION = os.environ.get("CALITP_BQ_LOCATION", "us-west2")


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


def get_engine(max_bytes=None):
    max_bytes = CALITP_BQ_MAX_BYTES if max_bytes is None else max_bytes

    cred_path = os.environ.get("CALITP_SERVICE_KEY_PATH")

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{get_project_id()}/?maximum_bytes_billed={max_bytes}",
        location=CALITP_BQ_LOCATION,
        credentials_path=cred_path,
    )


def get_table(table_name, as_df=False):
    engine = get_engine()
    src_table = format_table_name(table_name)

    table = Table(src_table, MetaData(bind=engine), autoload=True)

    if as_df:
        return pd.read_sql_query(table.select(), engine)

    return table


@singledispatch
@require_pipeline("write_table")
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
@require_pipeline("write_table")
def _write_table_df(sql_stmt, table_name, engine=None, replace=True):
    if_exists = "replace" if replace else "fail"
    return sql_stmt.to_gbq(
        format_table_name(table_name), project_id=get_project_id(), if_exists=if_exists
    )


def query_sql(fname, write_as=None, replace=False, dry_run=False, as_df=True):
    if fname.endswith(".yml") or fname.endswith(".yaml"):
        config = yaml.safe_load(open(fname))

        sql_template_raw = config["sql"]
    else:
        sql_template_raw = fname

    env = Environment(autoescape=True)
    env.filters = {**env.filters, **user_defined_filters}

    template = env.from_string(sql_template_raw)

    sql_code = template.render({**user_defined_macros})

    if dry_run:
        return sql_code
    elif write_as is not None:
        return write_table(sql_code, write_as, replace=replace)
    else:
        engine = get_engine()

        if as_df:
            return pd.read_sql_query(sql_code, engine)

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


def sql_patch_comments(table_name, field_comments, table_comments=None, bq_client=None):
    """Patch an existing table with new column descriptions."""

    if bq_client is None:
        from google.cloud import bigquery

        bq_client = bigquery.Client(
            project=get_project_id(), location=CALITP_BQ_LOCATION
        )

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
    tbl.description = table_comments if table_comments is not None else tbl.description

    bq_client.update_table(tbl, ["schema", "description"])
