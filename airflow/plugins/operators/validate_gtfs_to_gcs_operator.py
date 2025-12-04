import json
import os
import tempfile
from typing import Sequence

import pendulum
from hooks.gtfs_validator_hook import GTFSValidatorHook

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class ValidateGTFSToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "download_schedule_feed_results",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        download_schedule_feed_results: dict,
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
        self.download_schedule_feed_results = download_schedule_feed_results
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.results_path = results_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def validator_hook(self, date: pendulum.DateTime) -> GTFSValidatorHook:
        return GTFSValidatorHook(date=date)

    def source_filename(self) -> str:
        return os.path.basename(self.source_path)

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        with tempfile.TemporaryDirectory() as tmp_dir:
            local_source_path = self.gcs_hook().download(
                bucket_name=self.source_name(),
                object_name=self.source_path,
                filename=os.path.join(tmp_dir, self.source_filename()),
            )
            validator_result = self.validator_hook(
                date=dag_run.logical_date,
            ).run(
                filename=local_source_path,
                download_schedule_feed_results=self.download_schedule_feed_results,
            )
            full_destination_path = (
                f"{self.destination_path}/{validator_result.filename()}"
            )

            if validator_result.notices():
                self.gcs_hook().upload(
                    bucket_name=self.destination_name(),
                    object_name=full_destination_path,
                    data="\n".join(
                        [
                            json.dumps(n, separators=(",", ":"))
                            for n in validator_result.notices()
                        ]
                    ),
                    mime_type="application/jsonl",
                    gzip=True,
                    metadata={
                        "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                            validator_result.validation()
                        )
                    },
                )

            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=self.results_path,
                data=json.dumps(validator_result.results(), separators=(",", ":")),
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
                self.destination_bucket, full_destination_path
            ),
            "results_path": os.path.join(self.destination_bucket, self.results_path),
        }
