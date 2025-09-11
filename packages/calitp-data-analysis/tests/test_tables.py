from warnings import catch_warnings

import pandas as pd
from calitp_data_analysis.tables import AttributeDict, AutoTable, TableFactory
from siuba.sql import LazyTbl  # type: ignore[import]


def test_attribute_dict_deprecation_warning():
    with catch_warnings(record=True) as warnings:
        AttributeDict()
        assert len(warnings) == 1
        assert issubclass(warnings[0].category, DeprecationWarning)
        assert (
            str(warnings[0].message)
            == "AttributeDict is deprecated and will be removed in the version after 2025.8.10."
        )


def test_auto_table_deprecation_warning(engine):
    with catch_warnings(record=True) as warnings:
        AutoTable(engine)
        assert len(warnings) == 1
        assert issubclass(warnings[0].category, DeprecationWarning)
        warning_message = str(warnings[0].message)
        expected_warning_beginning = "AutoTable is deprecated and will be removed in the version after 2025.8.10."
        assert (
            expected_warning_beginning in warning_message
        ), f"{warning_message} does not match expected pattern"


def test_table_factory_deprecation_warning(engine, tmp_name):
    with catch_warnings(record=True) as warnings:
        TableFactory(engine, tmp_name)
        assert len(warnings) == 1
        assert issubclass(warnings[0].category, DeprecationWarning)
        assert (
            str(warnings[0].message)
            == "TableFactory is deprecated and will be removed in the version after 2025.8.10."
        )


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
