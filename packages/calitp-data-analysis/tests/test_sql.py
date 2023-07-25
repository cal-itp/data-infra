import datetime
from pathlib import Path

from calitp_data_analysis.sql import USER_DEFINED_MACROS, get_table, query_sql


def test_get_table():
    get_table("mart_transit_database.dim_gtfs_datasets", as_df=True)


def test_query_sql_and_file(engine, tmp_path):
    p_query = Path(tmp_path) / "query.yml"
    p_query.write_text("""sql: SELECT {{THE_FUTURE}}""")

    query_txt = query_sql(str(p_query), dry_run=True, as_df=False, engine=engine)
    assert query_txt == f"SELECT {USER_DEFINED_MACROS['THE_FUTURE']}"

    res = query_sql(str(p_query), as_df=False, engine=engine)
    assert res.fetchall() == [(datetime.date(2099, 1, 1),)]


def test_query_sql_as_df(engine):
    df = query_sql("SELECT 1 AS n", engine=engine)
    assert len(df) == 1
    assert "n" in df.columns
