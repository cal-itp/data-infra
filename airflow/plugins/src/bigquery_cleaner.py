import re
from typing import Any


def is_float(value) -> bool:
    if isinstance(value, float):
        return True
    elif isinstance(value, str):
        try:
            return (
                True
                if value.replace(".", "", 1).isdigit()
                and value.count(".") == 1
                and float(value)
                else False
            )
        except ValueError:
            return False
    else:
        return False


def is_dict(value) -> bool:
    if isinstance(value, dict):
        return True
    elif isinstance(value, str):
        if value[0:1] == "{" and value[-1:1] == "}":
            return True
        else:
            return False
    else:
        return False


class BigQueryValueCleaner:
    value: Any

    def __init__(self, value: Any):
        self.value = value

    def clean(self):
        """
        BigQuery doesn't allow arrays that contain null values --
        see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
        Therefore we need to manually replace None with falsy values according
        to the type of data in the array.
        """
        result = self.value

        # if isinstance(result, str):

        if is_dict(result):
            for k, v in result.items():
                if isinstance(v, dict):
                    result[k] = BigQueryRowCleaner(v).clean()
                else:
                    result[k] = BigQueryValueCleaner(v).clean()
        elif isinstance(result, list):
            types = set(type(entry) for entry in result if entry is not None)
            if not types:
                result = []
            elif types <= {int, float}:
                result = [x if x is not None else -1 for x in result]
            else:
                result = [x if x is not None else "" for x in result]
        elif is_float(result):
            result = round(float(result), 8)

        return result


class BigQueryKeyCleaner:
    key: Any

    def __init__(self, key: Any):
        self.key = key

    def clean(self) -> str:
        """Replace non-word characters.
        See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers.
        Add underscore if starts with a number.  Also sometimes excel has columns names that are
        all numbers, not even strings of numbers (ﾉﾟ0ﾟ)ﾉ~
        """
        if not isinstance(self.key, str):
            self.key = str(self.key)
        if self.key[:1].isdigit():
            self.key = "_" + self.key
        return str.lower(re.sub(r"[^\w]", "_", self.key))


class BigQueryRowCleaner:
    row: dict

    def __init__(self, row: dict):
        self.row = row

    def clean(self) -> dict:
        columns = {}
        for key, value in self.row.items():
            columns[BigQueryKeyCleaner(key).clean()] = BigQueryValueCleaner(
                value
            ).clean()
        return columns


class BigQueryCleaner:
    rows: list

    def __init__(self, rows: list):
        self.rows = rows

    def clean(self) -> list:
        return [BigQueryRowCleaner(row).clean() for row in self.rows]
