from typing import Sequence

import pendulum

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class UniquePartitionValues:
    def __init__(
        self, gcs_hook: GCSHook, bucket_name: str, partition_name: str, feed: str
    ) -> None:
        self.gcs_hook = gcs_hook
        self.bucket_name = bucket_name
        self.partition_name = partition_name
        self.feed = feed

    def get(self, logical_date: str):
        date = logical_date.replace(minute=0, second=0)
        keys = self.gcs_hook.list(
            bucket_name=self.bucket_name,
            prefix=f"{self.feed}/dt={date.date().isoformat()}/hour={date.isoformat()}/",
        )

        partitions = []
        for path in keys:
            # path = trip_updates/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00/ts=2024-10-22T18:59:40+00:00/base64_url=aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1HRw==/feed
            for partition in path.split("/"):
                # partition = [ "trip_updates", "dt=2024-10-22", "hour=2024-10-22T18:00:00+00:00", "ts=2024-10-22T18:59:40+00:00", "base64_url=aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1HRw==", "feed"]
                if partition.startswith(f"{self.partition_name}="):
                    # partition_name = "base64_url"
                    # partition = "base64_url=aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1HRw=="
                    name_size = len(f"{self.partition_name}=")
                    # Append value without the partition name and first equals sign: "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1HRw=="
                    partitions.append(partition[name_size:])
        return list(set(partitions))


class CommandBuilder:
    def __init__(self, command: list[str]) -> None:
        self.command = command

    def format(self, **arguments) -> str:
        return " ".join(self.command).format(**arguments)


class GCSToGTFSRTCommandOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "process",
        "feed",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        process: str,
        feed: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.process = process
        self.feed = feed
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def base64_urls(self) -> list:
        return UniquePartitionValues(
            gcs_hook=self.gcs_hook(),
            bucket_name=self.bucket_name(),
            feed=self.feed,
            partition_name="base64_url",
        )

    def command_builder(self) -> CommandBuilder:
        return CommandBuilder(
            command=[
                "python3",
                "$HOME/gcs/plugins/scripts/gtfs_rt_parser.py",
                self.process,
                self.feed,
                "{timestamp}",
                "--base64url",
                "{base64_url}",
                "--verbose",
            ]
        )

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        logical_date: pendulum.DateTime = pendulum.instance(dag_run.logical_date)
        timestamp = logical_date.replace(minute=0, second=0).format(
            "YYYY-MM-DDTHH:mm:ss"
        )
        commands = [
            self.command_builder().format(timestamp=timestamp, base64_url=base64_url)
            for base64_url in self.base64_urls().get(logical_date)
        ]
        return commands
