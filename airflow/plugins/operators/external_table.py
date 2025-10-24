"""
Abstracts the various concerns of external table creation as much as possible

This operator originally ran using airflow's bigquery hooks. However, for the
version we had to use (airflow v1.14) they used an outdated form of authentication.
Now, the pipeline aims to use bigquery's sqlalchemy client where possible.
However, it's cumbersome to convert the http api style schema fields to SQL, so
we provide a fallback for these old-style tasks.
"""

from google.api_core.exceptions import NotFound
from google.cloud import bigquery
from utils import CALITP_BQ_LOCATION, CALITP_PROJECT_NAME

from airflow.models import BaseOperator


def format_table_name(name, is_staging=False, full_name=False):
    dataset, table_name = name.split(".")
    staging = "__staging" if is_staging else ""

    project_id = CALITP_PROJECT_NAME + "." if full_name else ""
    # e.g. test_gtfs_schedule__staging.agency

    return f"{project_id}{dataset}.{table_name}{staging}"


def _bq_client_create_external_table(
    table_name,
    schema_fields,
    source_objects,
    source_format,
    geojson=False,
    hive_options=None,
    bucket=None,
    post_hook=None,
):
    # TODO: must be fully qualified table name
    ext = bigquery.ExternalConfig(source_format)
    ext.source_uris = source_objects
    ext.autodetect = schema_fields is None
    ext.ignore_unknown_values = True

    if geojson:
        ext.json_extension = "GEOJSON"

    if hive_options:
        assert (
            len(source_objects) == 1
        ), "cannot use hive partitioning with more than one URI"
        opt = bigquery.external_config.HivePartitioningOptions()
        # _Strongly_ recommend using CUSTOM mode and explicitly-defined
        # key schema for more than a trivial number of files
        opt.mode = hive_options.get("mode", "AUTO")
        opt.require_partition_filter = hive_options.get(
            "require_partition_filter", True
        )
        # TODO: this is very fragile, we should probably be calculating it from
        #       the source_objects and validating the format (prefix, trailing slashes)
        prefix = hive_options["source_uri_prefix"]

        if prefix and bucket:
            opt.source_uri_prefix = bucket + "/" + prefix
        else:
            opt.source_uri_prefix = prefix
        ext.hive_partitioning = opt

    client = bigquery.Client(project=CALITP_PROJECT_NAME, location=CALITP_BQ_LOCATION)

    dataset_name, _ = table_name.split(".")
    full_dataset_name = ".".join((CALITP_PROJECT_NAME, dataset_name))

    try:
        client.get_dataset(full_dataset_name)
    except NotFound:
        print(f"Dataset {full_dataset_name} not found, creating.")
        dataset = bigquery.Dataset(full_dataset_name)
        dataset.location = CALITP_BQ_LOCATION
        client.create_dataset(dataset, timeout=30)

    # for some reason, you can set the project name in the bigquery client, and
    # it doesn't need to be in the SQL code, but this bigquery API still requires
    # the fully qualified table name when initializing a Table.
    full_table_name = f"{CALITP_PROJECT_NAME}.{table_name}"

    # First delete table if it exists
    print(f"Deleting external table if exists: {full_table_name}")
    client.delete_table(full_table_name, not_found_ok=True)

    # (re)create table
    tbl = bigquery.Table(full_table_name, schema_fields)
    tbl.external_data_configuration = ext

    print(
        f"Creating external table: {full_table_name} {tbl} {source_objects} {hive_options}"
    )
    created_table = client.create_table(tbl, timeout=300, exists_ok=True)

    if post_hook:
        client.query(post_hook).result()
        print(f"Successfully ran {post_hook}")

    return created_table


class ExternalTable(BaseOperator):
    template_fields = (
        "bucket",
        "post_hook",
    )

    def __init__(
        self,
        *args,
        bucket=None,
        destination_project_dataset_table=None,  # note that the project is optional here
        skip_leading_rows=1,
        schema_fields=None,
        hive_options=None,
        source_objects=[],
        source_format="CSV",
        geojson=False,
        use_bq_client=False,
        field_delimiter=",",
        post_hook=None,
        **kwargs,
    ):
        assert bucket is not None
        self.bucket = bucket
        self.destination_project_dataset_table = format_table_name(
            destination_project_dataset_table
        )
        self.skip_leading_rows = skip_leading_rows
        self.schema_fields = schema_fields
        self.source_objects = source_objects
        self.source_format = source_format
        self.geojson = geojson
        self.hive_options = hive_options
        self.use_bq_client = use_bq_client
        self.field_delimiter = field_delimiter
        self.post_hook = post_hook

        super().__init__(**kwargs)

    def execute(self, context):
        # we can't do this in the init because templating occurs in the super init call
        self.source_objects = list(map(self.fix_prefix, self.source_objects))
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
                self.geojson,
                self.hive_options,
                self.bucket,
                self.post_hook,
            )

        else:
            if self.hive_options:
                raise RuntimeError(
                    "have to use the bigquery client when creating a hive partitioned table"
                )

            field_strings = [
                f'{entry["name"]} {entry["type"]}' for entry in self.schema_fields
            ]
            fields_spec = ",\n".join(field_strings)

            options = [
                f'format = "{self.source_format}"',
                f"uris = {repr(self.source_objects)}",
            ]

            if self.source_format == "CSV":
                options.append(f"skip_leading_rows = {self.skip_leading_rows}")
                options.append(f"field_delimiter = {repr(self.field_delimiter)}")

            if self.geojson:
                options.append("json_extension = 'GEOJSON'")

            options_str = ",".join(options)
            query = f"""
CREATE OR REPLACE EXTERNAL TABLE `{self.destination_project_dataset_table}` (
    {fields_spec}
)
OPTIONS ({options_str})
            """

            print(query)
            client = bigquery.Client(
                project=CALITP_PROJECT_NAME, location=CALITP_BQ_LOCATION
            )
            query_job = client.query(query)
            query_job.result()

        return self.schema_fields

    def fix_prefix(self, entry):
        entry = entry.replace("gs://", "") if entry.startswith("gs://") else entry
        return f"{self.bucket}/{entry}"
