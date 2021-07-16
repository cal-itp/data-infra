from calitp.config import (
    CALITP_BQ_LOCATION,
    get_bucket,
    get_project_id,
    format_table_name,
)

from calitp.sql import get_engine
from google.cloud import bigquery

from airflow.models import BaseOperator


# This operator originally ran using airflow's bigquery hooks. However, for the
# version we had to use (airflow v1.14) they used an outdated form of authentication.
# Now, the pipeline aims to use bigquery's sqlalchemy client where possible.
# However, it's cumbersome to convert the http api style schema fields to SQL, so
# we provide a fallback for these old-style tasks.
def _bq_client_create_external_table(
    table_name, schema_fields, source_objects, source_format
):
    # TODO: must be fully qualified table name
    ext = bigquery.ExternalConfig(source_format)
    ext.source_uris = source_objects

    client = bigquery.Client(project=get_project_id(), location=CALITP_BQ_LOCATION)

    # for some reason, you can set the project name in the bigquery client, and
    # it doesn't need to be in the SQL code, but this bigquery API still requires
    # the fully qualified table name when initializing a Table..
    full_table_name = f"{get_project_id()}.{table_name}"

    print(f"Creating external table: {full_table_name}")

    tbl = bigquery.Table(full_table_name, schema_fields)
    tbl.external_data_configuration = ext

    return client.create_table(tbl, timeout=300, exists_ok=True)


class ExternalTable(BaseOperator):
    def __init__(
        self,
        *args,
        bucket=None,
        destination_project_dataset_table=None,
        skip_leading_rows=1,
        schema_fields=None,
        source_objects=[],
        source_format="CSV",
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
        self.source_format = source_format
        self.use_bq_client = use_bq_client

        super().__init__(**kwargs)

    def execute(self, context):
        # Basically for backwards support of tasks that have nested fields and
        # were created when we were using airflow bigquery hooks.
        # e.g. dags/gtfs_schedule_history/validation_report.yml
        # These tables should be defined using SqlQueryOperator and raw SQL now.
        if self.use_bq_client:
            _bq_client_create_external_table(
                self.destination_project_dataset_table,
                self.schema_fields,
                self.source_objects,
                self.source_format,
            )

        else:
            field_strings = [
                f'{entry["name"]} {entry["type"]}' for entry in self.schema_fields
            ]
            fields_spec = ",\n".join(field_strings)

            query = f"""
CREATE OR REPLACE EXTERNAL TABLE `{self.destination_project_dataset_table}` (
    {fields_spec}
)
OPTIONS (
    format = "{self.source_format}",
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
