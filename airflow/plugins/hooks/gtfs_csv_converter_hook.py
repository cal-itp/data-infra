import csv
import json
import logging
import os
from io import StringIO
from itertools import islice
from typing import Generator, Self

from airflow.hooks.base import BaseHook


class GTFSCSVResults:
    def __init__(
        self,
        current_date: str,
        extracted_file: dict,
        extract_config: dict,
        filename: str,
        fieldnames: list[str],
        dialect: str,
    ) -> None:
        self.current_date = current_date
        self.filename = filename
        self.fieldnames = fieldnames
        self.dialect = dialect
        self.extracted_file = extracted_file
        self.extract_config = extract_config
        self.lines = []
        self._exception = None

    def filetype(self) -> str:
        return os.path.splitext(self.filename)[0]

    def set_exception(self, exception: Exception) -> None:
        self._exception = exception

    def exception(self) -> str | None:
        return str(self._exception) if self._exception is not None else None

    def append(self, row) -> None:
        self.lines.append({"_line_number": len(self.lines) + 1, **row})

    def chunks(self, size: int = 50_000) -> Generator[str, None, None]:
        iterator = iter(self.lines)
        for line in iterator:

            def chunk():
                yield json.dumps(line, separators=(",", ":"))
                for more in islice(iterator, size - 1):
                    yield json.dumps(more, separators=(",", ":"))

            yield chunk()

    def valid(self) -> bool:
        return len(self.lines) > 0

    def success(self) -> bool:
        return self._exception is None

    def report(self) -> dict:
        return {
            "exception": self.exception(),
            "feed_file": self.extracted_file,
            "fields": self.fieldnames,
            "parsed_file": self.metadata(),
            "success": self.success(),
        }

    def metadata(self) -> dict:
        return {
            "csv_dialect": self.dialect,
            "extract_config": self.extract_config,
            "filename": f"{self.filetype()}.jsonl.gz",
            "gtfs_filename": self.filetype(),
            "num_lines": len(self.lines),
            "ts": self.current_date,
        }


class NullReader:
    def __init__(self) -> None:
        self.fieldnames = []
        self.dialect = "excel"

    def __iter__(self) -> Self:
        return self

    def __next__(self) -> None:
        raise TypeError("Extracted file is empty")


class GTFSCSVConverter(BaseHook):
    def __init__(
        self,
        filename: str,
        data: bytes,
        extracted_file: dict,
        extract_config: dict,
    ) -> None:
        self.filename: str = filename
        self.data: bytes = data
        self.extracted_file: dict = extracted_file
        self.extract_config: dict = extract_config

    def _reader(self) -> csv.DictReader:
        if self.data is None or len(self.data) == 0:
            return NullReader()
        comma_reader = csv.DictReader(
            StringIO(self.data.decode("utf-8-sig")), restkey="calitp_unknown_fields"
        )
        tab_reader = csv.DictReader(
            StringIO(self.data.decode("utf-8-sig")),
            dialect="excel-tab",
            restkey="calitp_unknown_fields",
        )
        if len(comma_reader.fieldnames) == 1 and len(tab_reader.fieldnames) > 1:
            return tab_reader
        return comma_reader

    def convert(self, current_date: str) -> GTFSCSVResults:
        reader = self._reader()
        results = GTFSCSVResults(
            current_date=current_date,
            filename=self.filename,
            fieldnames=reader.fieldnames,
            dialect=reader.dialect,
            extracted_file=self.extracted_file,
            extract_config=self.extract_config,
        )
        try:
            for row in reader:
                results.append(row)
        except Exception as exception:
            results.set_exception(exception)
            logging.warning(f"Error adding lines on file {self.filename}: {exception}")
        return results
