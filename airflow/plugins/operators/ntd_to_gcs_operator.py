import json
import logging
import os
from datetime import datetime
from typing import Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.hooks.http_hook import HttpHook
from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class NTDObjectPath:
    def __init__(self, product: str, year: str) -> None:
        self.product = product
        self.year = year

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            self.product,
            self.year,
            f"dt={logical_date.date().isoformat()}",
            f"execution_ts={logical_date.isoformat()}",
            f"{self.year}__{self.product}.jsonl.gz",
        )


class NTDToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "product",
        "year",
        "endpoint",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        product: str,
        year: str,
        endpoint: str,
        parameters: dict = {},
        http_conn_id: str = "http_ntd",
        gcp_conn_id: str = "google_cloud_default",
        page_size: int = 100000,
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.product = product
        self.year = year
        self.endpoint = endpoint
        self.parameters = parameters
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id
        self.page_size = page_size

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> NTDObjectPath:
        return NTDObjectPath(product=self.product, year=self.year)

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def http_hook(self) -> HttpHook:
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        """Fetch all data using pagination and return cleaned rows."""
        all_rows = []
        offset = 0

        # Get the original limit from parameters, or use a large default
        original_limit = self.parameters.get("$limit", 5000000)

        logging.info(
            f"Starting paginated fetch for {self.product} with page size {self.page_size}"
        )

        while True:
            # Create parameters for this page
            page_params = self.parameters.copy()
            page_params["$limit"] = min(self.page_size, original_limit - offset)
            page_params["$offset"] = offset

            logging.info(
                f"Fetching page: offset={offset}, limit={page_params['$limit']}"
            )

            # Fetch this page
            try:
                result = (
                    self.http_hook()
                    .run(endpoint=self.endpoint, data=page_params)
                    .json()
                )
            except Exception as e:
                logging.error(f"Error fetching page at offset {offset}: {e}")
                raise

            # If no results, we're done
            if not result or len(result) == 0:
                logging.info(
                    f"No more data found at offset {offset}. Pagination complete."
                )
                break

            # Clean and add rows from this page
            cleaned_page = BigQueryCleaner(result).clean()
            page_rows = [json.dumps(x, separators=(",", ":")) for x in cleaned_page]
            all_rows.extend(page_rows)

            logging.info(f"Fetched {len(result)} rows, total so far: {len(all_rows)}")

            # Check if we've reached the original limit or got fewer rows than requested
            offset += len(result)
            if len(result) < page_params["$limit"] or offset >= original_limit:
                logging.info(
                    f"Pagination complete. Total rows fetched: {len(all_rows)}"
                )
                break

        return all_rows

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
