from calitp_data_analysis.sql import get_table, query_sql

# TODO: set up a separate project for CI, so our CI doesn't have permission
# to create / delete prod tables. Bigquery lets you set read access on individual
# datasets, but write access happens at the project level. Working around now
# by creating a table outside CI, then only testing reading it.


def test_get_table():
    get_table("mart_transit_database.dim_gtfs_datasets", as_df=True)


def test_query_sql():
    import datetime
    import tempfile
    from pathlib import Path

    from calitp_data.templates import user_defined_macros

    with tempfile.TemporaryDirectory() as dir_name:
        p_query = Path(dir_name) / "query.yml"
        p_query.write_text("""sql: SELECT {{THE_FUTURE}}""")

        query_txt = query_sql(str(p_query), dry_run=True, as_df=False)
        assert query_txt == f"SELECT {user_defined_macros['THE_FUTURE']}"

        res = query_sql(str(p_query), as_df=False)
        assert res.fetchall() == [(datetime.date(2099, 1, 1),)]


def test_query_sql_as_df():
    df = query_sql("SELECT 1 AS n")
    assert len(df) == 1
    assert "n" in df.columns
