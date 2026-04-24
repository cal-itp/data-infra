import json
import logging
import os
from typing import Sequence

from hooks.gtfs_csv_converter_hook import GTFSCSVConverter

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GTFSCSVToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dt",
        "ts",
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
        dt: str,
        ts: str,
        unzip_results: dict,
        source_bucket: str,
        source_path_fragment: str,
        destination_bucket: str,
        destination_path_fragment: str,
        results_path_fragment: str,
        chunk_size: int = 50_000,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.dt: str = dt
        self.ts: str = ts
        self.unzip_results = unzip_results
        self.source_bucket = source_bucket
        self.source_path_fragment = source_path_fragment
        self.destination_bucket = destination_bucket
        self.results_path_fragment = results_path_fragment
        self.destination_path_fragment = destination_path_fragment
        self.chunk_size = chunk_size
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
        extract_config = self.unzip_results.get("extract").get("config")
        for extracted_file in self.unzip_results["extracted_files"]:
            extracted_filename = extracted_file["filename"]
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
                    data=source,
                    extracted_file=extracted_file,
                    extract_config=extract_config,
                )
            )
        return output

    def execute(self, context: Context) -> str:
        output = []
        for converter in self.converters():
            logging.info(f"Converting {converter.filename}")
            results = converter.convert(current_date=self.ts)
            if results.valid():
                for index, chunk in enumerate(results.chunks(size=self.chunk_size)):
                    self.gcs_hook().upload(
                        bucket_name=self.destination_name(),
                        object_name=os.path.join(
                            results.filetype(),
                            self.destination_path_fragment,
                            f"{results.filetype()}-{str(index + 1).zfill(3)}.jsonl.gz",
                        ),
                        data="\n".join(chunk),
                        mime_type="application/jsonl",
                        gzip=True,
                        metadata={
                            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                                results.metadata()
                            )
                        },
                    )

                    output.append(
                        {
                            "dt": self.dt,
                            "ts": self.ts,
                            "destination_path": os.path.join(
                                results.filetype(),
                                self.destination_path_fragment,
                                f"{results.filetype()}-{str(index + 1).zfill(3)}.jsonl.gz",
                            ),
                            "results_path": os.path.join(
                                f"{results.filename}_parsing_results",
                                self.results_path_fragment,
                            ),
                        }
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
                            "ts": self.ts,
                        }
                    )
                },
            )

        return output
