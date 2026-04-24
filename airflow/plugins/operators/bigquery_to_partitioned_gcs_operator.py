"""
Goal: use a DAG to take `mart_gtfs.fct_vehicle_locations` -> 
use movingpandas / Python to add trajectory -> 
results are configured external table, usable in downstream dbt model `mart_gtfs.fct_vehicle_locations_path`.

1. Be able to grab a week for `mart_gtfs.fct_vehicle_locations` for each DAG run,
save it into a hive-partitioned GCS bucket. 
Laurie: we have to have Airflow job to define partitions in explicit way.
  - [ ] use 1 bucket (make sure naming convention is correct)
  - [ ] ask MoV to use Terraform to set up
  - [ ] add `fct_vehicle_locations` in chunks, 1 week at a time, filter on dt, only necessary columns, saved to hive-partitioned GCS.
        save as gzipped jsonl? 
        BUCKET/fct_vehicle_locations/dt=2026-01-01; 
        BUCKET/fct_vehicle_locations/dt=2026-01-02; is this how partitions look like? 

2. Add a Python script that models the vehicle location trajectory (use movingpandas).
Laurie: script would operate on each partition at a time, so every dt
- [ ] movingpandas chunk - read in json, save results as gzipped jsonl 
- [ ] I need to double check results are what's expected / use it downstream and make sure
- [ ] movingpandas results also come out in chunks, 1 week at a time, saved to hive-partitioned GCS. 
      vehicle_locations_trajectory (? clear enough name?)
        BUCKET/vehicle_locations_trajectory/dt=2026-01-01; 
        BUCKET/vehicle_locations_trajectory/dt=2026-01-02; is this how partitions look like? 

3. Configure the results in BUCKET/vehicle_locations_trajectory/dt=* to be external table
- [ ] use the create_external_table DAG
- [ ] set the partitions (dt), clusters, 
- [ ] test that I can see it, use the 2 sources together in `fct_vehicle_locations_path` 

Airflow operators to use as examples: 
- bigquery_to_download_config_operator (selects subset of columns) 
- tdq_bigquery_rows_operator (selects a BQ table and returns it) 
- DAG: create_external_table - no current examples, we've moved much away 
"""
import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook

class BigQueryToPartitionedGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "ts",
        "dataset_name",
        "table_name",
        "destination_bucket",
        "destination_path",
        "columns",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        ts: str,
        destination_bucket: str,
        destination_path: str,
        columns: list[str] = [
            "key",
            "dt",
            "service_date",
            "base64_url",
            "trip_instance_key",
            "position_longitude",
            "position_latitude",
            "location_timestamp"
        ],
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._big_query_hook = None
        self.ts: str = ts
        self.dataset_name = dataset_name
        self.table_name = table_name
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.columns = columns
        self.gcp_conn_id = gcp_conn_id
        # does start_date and end_date get defined here to be used in sql?

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def location(self) -> str:
        return os.getenv("CALITP_BQ_LOCATION")

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id, location=self.location(), use_legacy_sql=False
        )

    def sql(self, start_date, end_date) -> str:
        selected_columns = ", ".join(self.columns) if self.columns else "*"
        return f"""
            SELECT {selected_columns}
            FROM `{self.dataset_name}.{self.table_name}`
            WHERE dt >= DATE('{start_date}') AND dt <= DATE('{end_date}')
        """

    def metadata(self) -> dict:
        return {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                {
                    "filename": "configs.jsonl.gz",
                    "ts": self.ts,
                }
            )
        }

    def execute(self, context: Context) -> str:
        client = self.bigquery_hook().get_client()
        query_job = client.query(self.sql())
        results = query_job.result()

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=data,
            mime_type="application/jsonl",
            gzip=True,
            metadata=self.metadata(),
        )
        return {"destination_path": self.destination_path}
