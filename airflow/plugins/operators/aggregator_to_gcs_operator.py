import csv
import io
import json
import os
from datetime import datetime
from typing import Dict, Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.hooks.http_hook import HttpHook
from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook

TRANSITLAND_FEED_FLAVORS: Dict[str, str] = {
    "gbfs_auto_discovery": "general_bikeshare_feed_specification",
    "mds_provider": "mobility_data_specification",
    "realtime_alerts": "service_alerts",
    "realtime_trip_updates": "trip_updates",
    "realtime_vehicle_positions": "vehicle_positions",
    "static_current": "schedule",
    "static_historic": "schedule",
    "static_planned": "schedule",
}


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
        http_conn_id: str = "http_mobility_database",
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
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        result = self.http_hook().run().text
        reader = csv.DictReader(io.StringIO(result))
        return [
            json.dumps(
                {
                    "key": r["mdb_source_id"],
                    "feed_url_str": r["urls.direct_download"],
                    "raw_record": r,
                },
                separators=(",", ":"),
            )
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


class TransitlandPage:
    def __init__(self, results: dict) -> None:
        self.results: dict = results

    def after(self) -> str | None:
        if "meta" in self.results and "after" in self.results["meta"]:
            return self.results["meta"]["after"]
        return None

    def rows(self) -> list:
        rows = []
        for feed in self.results["feeds"]:
            for flavor, urls in feed["urls"].items():
                for i, url in enumerate([urls] if isinstance(urls, str) else urls):
                    rows.append(
                        {
                            "key": f"{feed['id']}_{flavor}_{i}",
                            "name": feed["name"],
                            "feed_url_str": url,
                            "feed_type": TRANSITLAND_FEED_FLAVORS[flavor],
                            "raw_record": {flavor: urls},
                        }
                    )
        return rows


class TransitlandPaginator:
    def __init__(self, http_hook: HttpHook, pages: int, parameters: dict) -> None:
        self.http_hook: HttpHook = http_hook
        self.pages: int = pages
        self.parameters: dict = parameters

    def result(self) -> dict:
        data = self.parameters.copy()
        rows = []
        for _ in range(0, self.pages):
            results = self.http_hook.run(data=data).json()
            page = TransitlandPage(results=results)
            rows.extend(page.rows())
            if not page.after():
                break
            data["after"] = page.after()
        return rows


class TransitlandToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        pages: int,
        parameters: dict = {},
        http_conn_id: str = "http_transitland",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket: str = bucket
        self.pages: int = pages
        self.parameters: dict = parameters
        self.http_conn_id: str = http_conn_id
        self.gcp_conn_id: str = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> AggregatorObjectPath:
        return AggregatorObjectPath(aggregator="transitland")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def http_hook(self) -> HttpHook:
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        paginator = TransitlandPaginator(
            http_hook=self.http_hook(), pages=self.pages, parameters=self.parameters
        )
        return [
            json.dumps(x, separators=(",", ":"))
            for x in BigQueryCleaner(paginator.result()).clean()
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
