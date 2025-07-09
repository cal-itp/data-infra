import json
import os
import csv
import io
from datetime import datetime
from typing import Any, Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.hooks.http_hook import HttpHook
from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class AggregatorObjectPath:
    def __init__(self, aggregator: str) -> None:
        self.aggregator = aggregator

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            "gtfs_aggregator_scrape_results",
            f"dt={logical_date.date().isoformat()}",
            f"ts={logical_date.isoformat()}",
            f"aggregator={self.aggregator}",
            "results.jsonl.gz",
        )


class MobilityDatabaseToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        http_conn_id: str = "http_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> AggregatorObjectPath:
        return AggregatorObjectPath(aggregator="mobility_database")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def http_hook(self) -> HttpHook:
        return HttpHook(method='GET', http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        result = self.http_hook().run().text
        reader = csv.DictReader(io.StringIO(result))
        return [
            json.dumps({"key": r["mdb_source_id"], "feed_url_str": r["urls.direct_download"], "raw_record": r}, separators=(",", ":"))
            for r in reader
        ]

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        object_name: str = self.object_path().resolve(dag_run.logical_date)
        self.gcs_hook().upload(
            bucket_name=self.bucket_name(),
            object_name=object_name,
            data="\n".join(self.cleaned_rows()),
            mime_type="application/jsonl",
            gzip=True,
        )
        return os.path.join(self.bucket, object_name)
