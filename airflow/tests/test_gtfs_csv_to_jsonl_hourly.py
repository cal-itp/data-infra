# we have to do this since Airflow imports are weird
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), "../plugins"))

from plugins.operators.gtfs_csv_to_jsonl_hourly import parse_csv_str  # noqa: E402


def test_parse_csv_str():
    csv = """
    a,b,c
    1,2,3
    1,2,3
    1,2,3
    """.strip()
    lines, fields, dialect = parse_csv_str(contents=csv)

    assert len(lines) == 3
    assert len(fields) == 3
    assert dialect == "excel"


def test_parse_csv_str_tsv():
    tsv = "\n".join(
        [
            "\t".join(row)
            for row in [
                ["a", "2", "c"],
                ["1", "2", "3"],
                ["1", "2", "3"],
                ["1", "2", "3"],
            ]
        ]
    )
    lines, fields, dialect = parse_csv_str(contents=tsv)

    assert len(lines) == 3
    assert len(fields) == 3
    assert dialect == "excel-tab"


def test_parse_csv_str_one_column():
    tsv = """
    a
    1
    1
    1
    """.strip()
    lines, fields, dialect = parse_csv_str(contents=tsv)

    assert len(lines) == 3
    assert len(fields) == 1
    assert dialect == "excel"
