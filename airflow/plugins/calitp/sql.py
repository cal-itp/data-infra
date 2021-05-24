import pandas as pd

from functools import singledispatch
from sqlalchemy.sql.expression import Executable, ClauseElement
from sqlalchemy.ext.compiler import compiles
from sqlalchemy import create_engine, Table, MetaData, sql

from calitp.utils import format_table_name, get_project_id

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


# SQL generic methods (with concrete implementations) ----


def get_table(table_name, as_df=False):
    engine = get_engine()
    src_table = format_table_name(table_name)

    table = Table(src_table, MetaData(bind=engine), autoload=True)

    if as_df:
        return pd.read_sql_query(table.select(), engine)

    return table


@singledispatch
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


@write_table.register(pd.DataFrame)
def _write_table_df(sql_stmt, table_name, engine=None, replace=True):
    if_exists = "replace" if replace else "fail"
    return sql_stmt.to_gbq(
        format_table_name(table_name), project_id=get_project_id(), if_exists=if_exists
    )
