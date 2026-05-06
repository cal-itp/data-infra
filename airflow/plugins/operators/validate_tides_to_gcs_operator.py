import gzip
import json
import os
import tempfile
from base64 import urlsafe_b64encode
from collections import Counter
from pathlib import Path
from typing import Sequence

import requests

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook

INTERNAL_COLUMNS = {
    "dt",
    "base64_url",
    "gtfs_dataset_key",
}


def _base64_url(url: str) -> str:
    return urlsafe_b64encode(url.encode()).decode()


def _feed_type_for(table: str) -> str:
    if "vehicle_locations" in table:
        return "tides_vehicle_locations"
    if "trips_performed" in table:
        return "tides_trips_performed"
    return f"tides_{table.replace('fct_tides_', '')}"


def _summarize_errors(report) -> tuple[bool, dict, str | None]:
    if not report.tasks:
        return report.valid, {}, (None if report.valid else "no tasks recorded")

    counts: Counter = Counter()
    for task in report.tasks:
        for err in task.errors:
            counts[err.type] += 1

    if report.valid:
        return True, dict(counts), None

    top = counts.most_common(5)
    exception = "; ".join(f"{etype}={count}" for etype, count in top)
    remainder = len(counts) - len(top)
    if remainder:
        exception = "%s; +%d more" % (exception, remainder)
    return False, dict(counts), exception


class ValidateTIDESToGCSOperator(BaseOperator):
    """Validate one feed's slice of a TIDES warehouse table against the TIDES
    JSON schema and write a JSON Lines outcome record to GCS.

    Mirrors the outcome envelope from `download_parse_and_validate_gtfs.py`
    so TIDES validation rows can land alongside GTFS validation rows in the
    same external-table layout for the Transit Data Quality team's
    Metabase dashboards.
    """

    template_fields: Sequence[str] = (
        "dt",
        "ts",
        "dataset_id",
        "table_name",
        "service_date",
        "gtfs_dataset_key",
        "feed_name",
        "feed_url",
        "schema_url",
        "destination_bucket",
        "outcome_path_prefix",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dt: str,
        ts: str,
        dataset_id: str,
        table_name: str,
        service_date: str,
        gtfs_dataset_key: str,
        feed_name: str,
        feed_url: str,
        schema_url: str,
        destination_bucket: str,
        outcome_path_prefix: str,
        row_limit: int | None = None,
        gcp_conn_id: str = "google_cloud_default",
        location: str = os.getenv("CALITP_BQ_LOCATION"),
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.dt = dt
        self.ts = ts
        self.dataset_id = dataset_id
        self.table_name = table_name
        self.service_date = service_date
        self.gtfs_dataset_key = gtfs_dataset_key
        self.feed_name = feed_name
        self.feed_url = feed_url
        self.schema_url = schema_url
        self.destination_bucket = destination_bucket
        self.outcome_path_prefix = outcome_path_prefix
        self.row_limit = row_limit
        self.gcp_conn_id = gcp_conn_id
        self.location = location

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id,
            location=self.location,
        )

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def time_column(self) -> str:
        return (
            "event_timestamp"
            if "vehicle_locations" in self.table_name
            else "actual_trip_start"
        )

    def export_query(self) -> str:
        sort_col = self.time_column()
        limit_clause = (
            f"\nORDER BY {sort_col}\nLIMIT {self.row_limit}" if self.row_limit else ""
        )
        return f"""
        SELECT * EXCEPT ({', '.join(sorted(INTERNAL_COLUMNS))})
        FROM `{self.dataset_id}.{self.table_name}`
        WHERE service_date = DATE @service_date
          AND gtfs_dataset_key = @gtfs_dataset_key{limit_clause}
        """

    def export_parquet(
        self, client, parquet_path: Path
    ) -> tuple[int, str | None, str | None]:
        # pandas + pyarrow get pulled in via the BQ client's `to_dataframe`
        # path; importing inside execute keeps DAG parse cheap.
        from google.cloud import bigquery

        job_config = bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter(
                    "service_date", "DATE", self.service_date
                ),
                bigquery.ScalarQueryParameter(
                    "gtfs_dataset_key", "STRING", self.gtfs_dataset_key
                ),
            ],
        )
        df = client.query(self.export_query(), job_config=job_config).to_dataframe()
        for col in df.select_dtypes(include=["float", "float64", "float32"]).columns:
            df[col] = df[col].astype(object).where(df[col].notna(), None)
        df.to_parquet(parquet_path, index=False)

        sort_col = self.time_column()
        first_event = None
        last_event = None
        if len(df) and sort_col in df.columns:
            non_null = df[sort_col].dropna()
            if not non_null.empty:
                lo = non_null.min()
                hi = non_null.max()
                first_event = lo.isoformat() if hasattr(lo, "isoformat") else str(lo)
                last_event = hi.isoformat() if hasattr(hi, "isoformat") else str(hi)
        return len(df), first_event, last_event

    def fetch_schema(self):
        from frictionless import Schema

        response = requests.get(self.schema_url, timeout=30)
        response.raise_for_status()
        return Schema.from_descriptor(response.json())

    def outcome_dict(
        self,
        row_count: int,
        first_event: str | None,
        last_event: str | None,
        report,
        blob_path: str,
        process_stderr: str | None = None,
        exception: str | None = None,
    ) -> dict:
        if report is not None:
            success, error_counts, summarized_exception = _summarize_errors(report)
            valid = report.valid
            if exception is None:
                exception = summarized_exception
        else:
            success = False
            error_counts = {}
            valid = False

        config = {
            "extracted_at": self.ts,
            "name": self.feed_name,
            "url": self.feed_url,
            "feed_type": _feed_type_for(self.table_name),
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {},
            "computed": True,
            "tides_schema_url": self.schema_url,
            "service_date": self.service_date,
            "gtfs_dataset_key": self.gtfs_dataset_key,
            "warehouse_table": self.table_name,
        }
        extract = {
            "filename": _base64_url(self.feed_url),
            "ts": self.ts,
            "config": config,
            "response_code": None,
            "response_headers": None,
        }
        aggregation = {
            "filename": f"validate_{_base64_url(self.feed_url)}.jsonl.gz",
            "step": "validate",
            "first_extract": extract,
        }
        return {
            "success": success,
            "exception": exception,
            "step": "validate",
            "extract": extract,
            "header": {
                "row_count": row_count,
                "feed_count": 1 if row_count else 0,
                "first_event_timestamp": first_event,
                "last_event_timestamp": last_event,
                "frictionless_valid": valid,
                "error_counts_by_type": error_counts,
            },
            "aggregation": aggregation,
            "blob_path": blob_path,
            "process_stderr": process_stderr,
        }

    def outcome_object_name(self) -> str:
        return os.path.join(
            self.outcome_path_prefix,
            f"dt={self.dt}",
            f"ts={self.ts}",
            f"base64_url={_base64_url(self.feed_url)}",
            f"validate_{_base64_url(self.feed_url)}.jsonl.gz",
        )

    def execute(self, context: Context) -> dict:
        from frictionless import Resource, system, validate
        from google.cloud import bigquery

        # Frictionless 5.x rejects "unsafe" file paths outside the worker's
        # CWD by default; we point the resource at a temp parquet file.
        system.trusted = True

        client = bigquery.Client(
            project=self.bigquery_hook().get_client().project,
            location=self.location,
        )

        outcome_object = self.outcome_object_name()
        blob_path = os.path.join(self.destination_bucket, outcome_object)

        row_count = 0
        first_event = None
        last_event = None
        report = None
        process_stderr = None
        exception = None

        with tempfile.TemporaryDirectory() as tmp_dir:
            parquet_path = Path(tmp_dir) / (
                f"{self.table_name}_{self.service_date}_{self.gtfs_dataset_key}.parquet"
            )
            try:
                schema = self.fetch_schema()
                row_count, first_event, last_event = self.export_parquet(
                    client, parquet_path
                )
                resource = Resource(
                    path=str(parquet_path),
                    schema=schema,
                    format="parquet",
                )
                report = validate(resource)
            except Exception as exc:
                self.log.exception("TIDES validation step failed")
                exception = str(exc)
                process_stderr = repr(exc)

            outcome = self.outcome_dict(
                row_count=row_count,
                first_event=first_event,
                last_event=last_event,
                report=report,
                blob_path=blob_path,
                process_stderr=process_stderr,
                exception=exception,
            )

            payload = json.dumps(outcome, separators=(",", ":")).encode()
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=outcome_object,
                data=gzip.compress(payload),
                mime_type="application/jsonl",
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        {
                            "filename": (
                                f"validate_{_base64_url(self.feed_url)}.jsonl.gz"
                            ),
                            "ts": self.ts,
                            "feed_type": _feed_type_for(self.table_name),
                            "base64_url": _base64_url(self.feed_url),
                        }
                    )
                },
            )

        return {
            "dt": self.dt,
            "ts": self.ts,
            "blob_path": blob_path,
            "success": outcome["success"],
            "row_count": row_count,
        }
