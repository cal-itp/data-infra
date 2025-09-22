import os

import pandas as pd
import yaml
from jinja2 import Environment
from sqlalchemy import MetaData, Table, create_engine, text
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.sql.expression import ClauseElement, Executable

CALITP_BQ_MAX_BYTES = os.environ.get("CALITP_BQ_MAX_BYTES", 5_000_000_000)
CALITP_BQ_LOCATION = os.environ.get("CALITP_BQ_LOCATION", "us-west2")

USER_DEFINED_FILTERS = dict(
    table=lambda x: format_table_name(x, is_staging=False, full_name=True),
    quote=lambda s: '"%s"' % s,
)
USER_DEFINED_MACROS = dict(
    THE_FUTURE='DATE("2099-01-01")',
)


def get_engine(max_bytes=None, project="cal-itp-data-infra"):
    max_bytes = CALITP_BQ_MAX_BYTES if max_bytes is None else max_bytes

    cred_path = os.environ.get("CALITP_SERVICE_KEY_PATH")

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{project}/?maximum_bytes_billed={max_bytes}",  # noqa: E231
        location=CALITP_BQ_LOCATION,
        credentials_path=cred_path,
    )


def format_table_name(name, is_staging=False, full_name=False):
    dataset, table_name = name.split(".")
    staging = "__staging" if is_staging else ""
    # test_prefix = "zzz_test_" if is_development() else ""
    test_prefix = ""

    project_id = "cal-itp-data-infra" + "." if full_name else ""
    # e.g. test_gtfs_schedule__staging.agency

    return f"{project_id}{test_prefix}{dataset}.{table_name}{staging}"


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


def get_table(table_name, as_df=False):
    engine = get_engine()
    src_table = format_table_name(table_name)

    table = Table(src_table, MetaData(), autoload_with=engine)

    if as_df:
        return pd.read_sql_query(table.select(), engine)

    return table


def query_sql(fname, dry_run=False, as_df=True, engine=None):
    if fname.endswith(".yml") or fname.endswith(".yaml"):
        config = yaml.safe_load(open(fname))

        sql_template_raw = config["sql"]
    else:
        sql_template_raw = fname

    env = Environment(autoescape=False)  # nosec B701
    env.filters = dict(
        **env.filters,
        **USER_DEFINED_FILTERS,
    )

    template = env.from_string(sql_template_raw)

    sql_code = template.render(USER_DEFINED_MACROS)

    if dry_run:
        return sql_code
    else:
        if not engine:
            engine = get_engine()

        if as_df:
            return pd.read_sql_query(sql_code, engine)

        with engine.connect() as connection:
            result = connection.execute(text(sql_code))

        return result


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
