from airflow.contrib.operators.bigquery_operator import (
    BigQueryCreateExternalTableOperator,
)
from functools import wraps
from google.cloud import bigquery

from calitp.config import (
    get_bucket,
    format_table_name,
)


class ExternalTable(BigQueryCreateExternalTableOperator):
    @wraps(BigQueryCreateExternalTableOperator.__init__)
    def __init__(
        self, *args, bucket=None, destination_project_dataset_table=None, **kwargs
    ):
        bucket = get_bucket().replace("gs://", "", 1) if bucket is None else bucket
        dst_table = format_table_name(destination_project_dataset_table)

        super().__init__(
            *args, bucket=bucket, destination_project_dataset_table=dst_table, **kwargs
        )

    def execute(self, context):
        # delete the external table, if it already exists
        bq_client = bigquery.Client()
        bq_client.delete_table(
            self.destination_project_dataset_table, not_found_ok=True
        )

        super().execute(context)

        return self.schema_fields
