import pandas as pd
from calitp_data_analysis.tables import AutoTable, TableFactory
from siuba.sql import LazyTbl  # type: ignore[import]


def test_auto_table_write(engine, tmp_name):
    schema_name, table_name = tmp_name.split(".")

    df = pd.DataFrame({"x": [1, 2, 3]})

    df.to_sql(name=tmp_name, con=engine, index=False)

    tbl = AutoTable(
        engine,
        lambda s: s,
        lambda s: True,
    )

    tbl._init()

    tbl_tmp = getattr(tbl.calitp_py, table_name)()

    assert isinstance(tbl_tmp, LazyTbl)


def test_auto_table_comments(engine, tmp_name):
    engine.execute(
        f"""
        CREATE TABLE `{tmp_name}` (
            x INT64 OPTIONS(description="x column"),
            y STRING OPTIONS(description="y column")
        )
        OPTIONS(
            description="the table comment"
        )
    """  # noqa: E231,E241,E202
    )

    # TODO: rather than using AutoTable, let's just use CalitpTable directly
    tbl_factory_tmp = TableFactory(engine, tmp_name)
    doc = tbl_factory_tmp._repr_html_()

    assert "x column" in doc
    assert "the table comment" in doc
