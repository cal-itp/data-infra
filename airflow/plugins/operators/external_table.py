from calitp.config import (
    get_bucket,
    format_table_name,
)
from calitp.sql import get_engine

# from google.cloud import bigquery

from airflow.models import BaseOperator

# This operator originally ran using airflow's bigquery hooks. However, for the
# version we had to use (airflow v1.14) they used an outdated form of authentication.
# Now, the pipeline aims to use bigquery's sqlalchemy client where possible.
# However, it's cumbersome to convert the http api style schema fields to SQL, so
# we provide a fallback for these old-style tasks.
# def _hook_params_to_bq_client(
#     table_name, skip_leading_rows, schema_fields, source_objects, format
#    ):
#    bigquery.Table(table_name, schema=)
#
#


class ExternalTable(BaseOperator):
    def __init__(
        self,
        *args,
        bucket=None,
        destination_project_dataset_table=None,
        skip_leading_rows=1,
        schema_fields=None,
        source_objects=[],
        format="csv",
        use_bq_client=False,
        **kwargs,
    ):
        self.bucket = bucket
        self.destination_project_dataset_table = format_table_name(
            destination_project_dataset_table
        )
        self.skip_leading_rows = skip_leading_rows
        self.schema_fields = schema_fields
        self.source_objects = list(map(self.fix_prefix, source_objects))
        self.format = format
        self.use_bq_client = use_bq_client

        super().__init__(**kwargs)

    def execute(self, context):
        field_strings = [
            f'{entry["name"]} {entry["type"]}' for entry in self.schema_fields
        ]
        fields_spec = ",\n".join(field_strings)

        query = f"""
        CREATE OR REPLACE EXTERNAL TABLE `{self.destination_project_dataset_table}` (
            {fields_spec}
        )
        OPTIONS (
            format = "{self.format}",
            skip_leading_rows = {self.skip_leading_rows},
            uris = {repr(self.source_objects)}
        )
        """

        print(query)

        # delete the external table, if it already exists
        engine = get_engine()
        engine.execute(query)

        return self.schema_fields

    def fix_prefix(self, entry):
        bucket = get_bucket() if not self.bucket else self.bucket
        entry = entry.replace("gs://", "") if entry.startswith("gs://") else entry

        return f"{bucket}/{entry}"
