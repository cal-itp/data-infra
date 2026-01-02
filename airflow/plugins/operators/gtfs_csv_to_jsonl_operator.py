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
    def __init__(
        self,
        current_date: pendulum.DateTime,
        unzip_results: dict,
        filename: str,
        fieldnames: list[str],
        dialect: str,
    ) -> None:
        self.current_date = current_date
        self.filename = filename
        self.fieldnames = fieldnames
        self.dialect = dialect
        self.unzip_results = unzip_results
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

    def jsonl(self) -> list[str]:
        return "\n".join(
            [json.dumps(line, separators=(",", ":")) for line in self.lines]
        )

    def valid(self) -> bool:
        return len(self.lines) > 0

    def success(self) -> bool:
        return self._exception is None

    def report(self) -> dict:
        return {
            "exception": self.exception(),
            "feed_file": self.unzip_results.get("extracted_files")[0],
            "fields": self.fieldnames,
            "parsed_file": self.metadata(),
            "success": self.success(),
        }

    def metadata(self) -> dict:
        return {
            "csv_dialect": self.dialect,
            "extract_config": self.unzip_results.get("extract").get("config"),
            "filename": f"{self.filetype()}.jsonl.gz",
            "gtfs_filename": self.filetype(),
            "num_lines": len(self.lines),
            "ts": self.current_date.isoformat(),
        }


class GTFSCSVConverter:
    def __init__(self, filename: str, csv_data: bytes, unzip_results: dict) -> None:
        self.filename = filename
        self.csv_data = csv_data
        self.unzip_results = unzip_results

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

    def convert(self, current_date: pendulum.DateTime) -> GTFSCSVResults:
        reader = self.reader()
        results = GTFSCSVResults(
            current_date=current_date,
            filename=self.filename,
            fieldnames=reader.fieldnames,
            dialect=reader.dialect,
            unzip_results=self.unzip_results,
        )
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
        "source_path_fragment",
        "destination_bucket",
        "results_path_fragment",
        "destination_path_fragment",
        "gcp_conn_id",
    )

    def __init__(
        self,
        unzip_results: dict,
        source_bucket: str,
        source_path_fragment: str,
        destination_bucket: str,
        destination_path_fragment: str,
        results_path_fragment: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.unzip_results = unzip_results
        self.source_bucket = source_bucket
        self.source_path_fragment = source_path_fragment
        self.destination_bucket = destination_bucket
        self.results_path_fragment = results_path_fragment
        self.destination_path_fragment = destination_path_fragment
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def source_filename(self) -> str:
        return os.path.basename(self.source_path)

    def converters(self) -> list[GTFSCSVConverter]:
        output = []
        for extracted_file in self.unzip_results["extracted_files"]:
            extracted_filename = extracted_file["filename"]
            print(f"Converting file: {extracted_filename}")
            source = self.gcs_hook().download(
                bucket_name=self.source_name(),
                object_name=os.path.join(
                    extracted_filename,
                    self.source_path_fragment,
                    extracted_filename,
                ),
            )
            output.append(
                GTFSCSVConverter(
                    filename=extracted_filename,
                    csv_data=source.decode(),
                    unzip_results=self.unzip_results,
                )
            )
        return output

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        output = []
        for converter in self.converters():
            results = converter.convert(current_date=dag_run.logical_date)
            print(f"Generating results for file: {results.filetype()}")
            if results.valid():
                self.gcs_hook().upload(
                    bucket_name=self.destination_name(),
                    object_name=os.path.join(
                        results.filetype(),
                        self.destination_path_fragment,
                        f"{results.filetype()}.jsonl.gz",
                    ),
                    data=results.jsonl(),
                    mime_type="application/jsonl",
                    gzip=True,
                    metadata={
                        "PARTITIONED_ARTIFACT_METADATA": json.dumps(results.metadata())
                    },
                )

            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=os.path.join(
                    f"{results.filename}_parsing_results", self.results_path_fragment
                ),
                data=json.dumps(results.report(), separators=(",", ":")),
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

            output.append(
                {
                    "destination_path": os.path.join(
                        results.filetype(),
                        self.destination_path_fragment,
                        f"{results.filetype()}.jsonl.gz",
                    ),
                    "results_path": os.path.join(
                        f"{results.filename}_parsing_results",
                        self.results_path_fragment,
                    ),
                }
            )

        print("End of conversion.")
        return output
