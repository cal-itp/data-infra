import json

from src.bigquery_cleaner import BigQueryKeyCleaner, BigQueryValueCleaner


class KubaDictCleaner:
    row: dict

    def __init__(self, row: dict):
        self.row = row

    def clean(self) -> dict:
        columns = {}
        for k, v in self.row.items():
            key = BigQueryKeyCleaner(k).clean()
            value = v
            if "::" in k and "{" in v:
                value = json.loads(v.replace("\\n", ""))
            if isinstance(value, dict):
                columns[key] = KubaDictCleaner(value).clean()
            elif value != "":
                columns[key] = BigQueryValueCleaner(value).clean()
        return columns


class KubaCleaner:
    rows: list

    def __init__(self, rows: list):
        self.rows = rows

    def clean(self) -> list:
        return [KubaDictCleaner(row).clean() for row in self.rows]
