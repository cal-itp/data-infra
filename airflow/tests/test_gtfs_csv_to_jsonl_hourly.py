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
    lines, fields = parse_csv_str(contents=csv)

    assert len(lines) == 3
    assert len(fields) == 3


def test_parse_csv_str_tsv():
    tsv = """
    a   b   c
    1   2   3
    1   2   3
    1   2   3
    """.strip()
    lines, fields = parse_csv_str(contents=tsv)

    assert len(lines) == 3
    assert len(fields) == 3
