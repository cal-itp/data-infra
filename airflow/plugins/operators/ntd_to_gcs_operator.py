import gzip
import logging
import os
from datetime import datetime
from typing import Sequence

import pandas as pd
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

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        object_name: str = self.object_path().resolve(dag_run.logical_date)

        # Stream data directly to compressed buffer to avoid memory accumulation
        import io

        buffer = io.BytesIO()

        with gzip.GzipFile(fileobj=buffer, mode="wb") as gz_file:
            offset = 0
            total_rows = 0
            original_limit = self.parameters.get("$limit", 5000000)

            logging.info(f"Downloading NTD data for {self.year} / {self.product}.")

            while True:
                # Create parameters for this page
                page_params = self.parameters.copy()
                page_params["$limit"] = min(self.page_size, original_limit - offset)
                page_params["$offset"] = offset

                try:
                    result = (
                        self.http_hook()
                        .run(endpoint=self.endpoint, data=page_params)
                        .json()
                    )
                except Exception as e:
                    logging.error(f"An error occurred: {e}")
                    raise

                # If no results, we're done
                if not result or len(result) == 0:
                    break

                # Clean the data and stream directly to file
                cleaned_data = BigQueryCleaner(result).clean()
                df_page = pd.DataFrame(cleaned_data)

                # Stream each row as JSONL directly to compressed file
                for _, row in df_page.iterrows():
                    json_line = row.to_json() + "\n"
                    gz_file.write(json_line.encode("utf-8"))
                    total_rows += 1

                logging.info(
                    f"Downloaded {len(result)} rows, total rows so far: {total_rows}"
                )

                # Check if we've reached the original limit or got fewer rows than requested
                offset += len(result)
                if len(result) < page_params["$limit"] or offset >= original_limit:
                    break

        if total_rows > 0:
            logging.info(
                f"Downloaded {self.product} data for {self.year} with {total_rows} rows!"
            )

            # Upload the compressed data with extended timeout and retry logic
            buffer.seek(0)
            data_size = len(buffer.getvalue())
            logging.info(f"Uploading {data_size} bytes to GCS...")

            # Retry upload up to 3 times with increasing timeout
            for attempt in range(3):
                try:
                    timeout = 300 + (attempt * 300)  # 5, 10, 15 minutes
                    logging.info(
                        f"Upload attempt {attempt + 1}/3 with {timeout}s timeout"
                    )

                    self.gcs_hook().upload(
                        bucket_name=self.bucket_name(),
                        object_name=object_name,
                        data=buffer.getvalue(),
                        mime_type="application/jsonl",
                        gzip=False,  # Already compressed
                        timeout=timeout,
                    )
                    logging.info(
                        f"Successfully uploaded {data_size} bytes to {object_name}"
                    )
                    break
                except Exception as e:
                    logging.warning(f"Upload attempt {attempt + 1} failed: {e}")
                    if attempt == 2:  # Last attempt
                        logging.error(f"All upload attempts failed. Final error: {e}")
                        raise
                    else:
                        logging.info("Retrying upload in 30 seconds...")
                        import time

                        time.sleep(30)
        else:
            logging.info(
                f"There is no data to download for {self.year} / {self.product}. Ending pipeline."
            )

        return os.path.join(self.bucket, object_name)
