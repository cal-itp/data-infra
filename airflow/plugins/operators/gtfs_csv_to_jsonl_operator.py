import csv
import json
import os
from io import StringIO
from typing import Sequence

import pendulum

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GTFSCSVResults:
    def __init__(self, fieldnames: list[str], dialect: str) -> None:
        self.fieldnames = fieldnames
        self.dialect = dialect
        self.lines = []
        self._exception = None

    def set_exception(self, exception: Exception) -> None:
        self._exception = exception

    def exception(self) -> str | None:
        return str(self._exception) if self._exception is not None else None

    def append(self, row) -> None:
        self.lines.append({"_line_number": len(self.lines) + 1, **row})

    def jsonl(self) -> list[str]:
        return "\n".join(
            [json.dumps(line, separators=(",", ":")) for line in self.lines]
        )

    def is_empty(self) -> bool:
        return len(self.lines) == 0

    def success(self) -> bool:
        return self._exception is None

    def report(
        self,
        filename: str,
        filetype: str,
        unzip_results: dict,
        current_date: pendulum.DateTime,
    ) -> dict:
        return {
            "exception": self.exception(),
            "feed_file": unzip_results.get("extracted_files")[0],
            "fields": self.fieldnames,
            "parsed_file": {
                "csv_dialect": self.dialect,
                "extract_config": unzip_results.get("extract").get("config"),
                "filename": filename,
                "gtfs_filename": filetype,
                "num_lines": len(self.lines),
                "ts": current_date.isoformat(),
            },
            "success": self.success(),
        }


class GTFSCSVConverter:
    def __init__(self, csv_data: bytes) -> None:
        self.csv_data = csv_data

    def reader(self) -> csv.DictReader:
        comma_reader = csv.DictReader(
            StringIO(self.csv_data), restkey="calitp_unknown_fields"
        )
        tab_reader = csv.DictReader(
            StringIO(self.csv_data),
            dialect="excel-tab",
            restkey="calitp_unknown_fields",
        )
        if len(comma_reader.fieldnames) == 1 and len(tab_reader.fieldnames) > 1:
            return tab_reader
        return comma_reader

    def convert(self) -> GTFSCSVResults:
        reader = self.reader()
        results = GTFSCSVResults(fieldnames=reader.fieldnames, dialect=reader.dialect)
        try:
            for row in reader:
                results.append(row)
        except Exception as exception:
            results.exception = exception
        return results


class GTFSCSVToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "unzip_results",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "results_path",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        unzip_results: dict,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.unzip_results = unzip_results
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.destination_bucket = destination_bucket
        self.results_path = results_path
        self.destination_path = destination_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def source_filename(self) -> str:
        return os.path.basename(self.source_path)

    def source(self) -> bytes:
        return self.gcs_hook().download(
            bucket_name=self.source_name(),
            object_name=self.source_path,
        )

    def converter(self) -> GTFSCSVConverter:
        return GTFSCSVConverter(csv_data=self.source().decode())

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        result = self.converter().convert()
        report = result.report(
            filename=os.path.basename(self.destination_path),
            filetype=self.destination_path.split("/")[0],
            unzip_results=self.unzip_results,
            current_date=dag_run.logical_date,
        )

        if not result.is_empty():
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=self.destination_path,
                data=result.jsonl(),
                mime_type="application/jsonl",
                gzip=True,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(report["parsed_file"])
                },
            )

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.results_path,
            data=json.dumps(report, separators=(",", ":")),
            mime_type="application/jsonl",
            gzip=False,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    {
                        "filename": "results.jsonl",
                        "ts": dag_run.logical_date.isoformat(),
                    }
                )
            },
        )
        return {
            "destination_path": os.path.join(
                self.destination_bucket, self.destination_path
            ),
            "results_path": os.path.join(self.destination_bucket, self.results_path),
        }
