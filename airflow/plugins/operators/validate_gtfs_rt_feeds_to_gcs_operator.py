import json
import os
import subprocess
import tempfile
from contextlib import ExitStack
from datetime import datetime
from typing import Sequence

import pendulum
from hooks.gtfs_rt_validator_hook import GTFSRTValidatorHook, GTFSRTValidatorResult

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class ValidateGTFSRTFeedsToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "schedule_bucket",
        "schedule_path",
        "source_bucket",
        "source_paths",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        schedule_bucket: str,
        schedule_path: str,
        source_bucket: str,
        source_paths: list[str],
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.schedule_bucket: str = schedule_bucket
        self.schedule_path: str = schedule_path
        self.source_bucket: str = source_bucket
        self.source_paths: list[str] = source_paths
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.results_path: str = results_path
        self.gcp_conn_id: str = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def validator_hook(self, current_date: pendulum.DateTime) -> GTFSRTValidatorHook:
        return GTFSRTValidatorHook(current_date=current_date)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def schedule_name(self) -> str:
        return self.schedule_bucket.replace("gs://", "")

    def results(self, current_date: pendulum.DateTime) -> GTFSRTValidatorResult:
        with ExitStack() as stack:
            tmp_directory = stack.enter_context(tempfile.TemporaryDirectory())
            schedule_file = stack.enter_context(
                self.gcs_hook().provide_file(
                    bucket_name=self.schedule_name(), object_name=self.schedule_path
                )
            )
            source_files = [
                stack.enter_context(
                    self.gcs_hook().provide_file(
                        bucket_name=self.source_name(),
                        object_name=source_path,
                        dir=tmp_directory,
                    )
                )
                for source_path in self.source_paths
            ]

            return self.validator_hook(current_date=current_date).run(
                schedule_path=schedule_file.name,
                feed_directory=tmp_directory.name,
                feed_paths=[f.name for f in source_files],
            )

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        results: GTFSRTValidatorResult = self.results(current_date=dag_run.logical_date)

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data="\n".join(
                [
                    json.dumps(notice, separators=(",", ":"))
                    for notice in results.notices()
                ]
            ),
            mime_type="application/jsonl",
            gzip=True,
        )

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.results_path,
            data="\n".join(
                [
                    json.dumps(report, separators=(",", ":"))
                    for report in results.report()
                ]
            ),
            mime_type="application/jsonl",
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    results.report_metadata(), separators=(",", ":")
                )
            },
        )

        return {
            "destination_path": self.destination_path,
            "results_path": self.results_path,
        }
