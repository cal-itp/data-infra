# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - parse_rt_service_alerts
# ---

from calitp.config import get_project_id
from google.api_core.exceptions import Conflict
from google.cloud import bigquery

field = bigquery.SchemaField

INTEGER = "INTEGER"
NULLABLE = "NULLABLE"
RECORD = "RECORD"
REPEATED = "REPEATED"
STRING = "STRING"
TIMESTAMP = "TIMESTAMP"

SCHEMA = [
    field(
        "metadata",
        RECORD,
        fields=[
            field("path", STRING, mode=NULLABLE),
            field("itp_id", INTEGER, mode=NULLABLE),
            field("url", INTEGER, mode=NULLABLE),
        ],
    ),
    field("id", STRING, mode=NULLABLE),
    field(
        "header",
        RECORD,
        mode=NULLABLE,
        fields=[
            field("timestamp", INTEGER, mode=NULLABLE),
            field("incrementality", STRING, mode=NULLABLE),
            field("gtfsRealtimeVersion", STRING, mode=NULLABLE),
        ],
    ),
    field(
        "alert",
        RECORD,
        fields=[
            field(
                "activePeriod",
                RECORD,
                mode=REPEATED,
                fields=[
                    field("start", INTEGER, mode=NULLABLE),
                    field("end", INTEGER, mode=NULLABLE),
                ],
            ),
            field(
                "informedEntity",
                RECORD,
                mode=REPEATED,
                fields=[
                    field("agencyId", STRING, mode=NULLABLE),
                    field("routeId", STRING, mode=NULLABLE),
                    field("routeType", INTEGER, mode=NULLABLE),
                    field("directionId", INTEGER, mode=NULLABLE),
                    field("stopId", STRING, mode=NULLABLE),
                    field(
                        "trip",
                        RECORD,
                        mode=NULLABLE,
                        fields=[
                            field("tripId", STRING, mode=NULLABLE),
                            field("routeId", STRING, mode=NULLABLE),
                            field("directionId", INTEGER, mode=NULLABLE),
                            field("startTime", STRING, mode=NULLABLE),
                            field("startDate", STRING, mode=NULLABLE),
                            field("scheduleRelationship", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field("cause", STRING, mode=NULLABLE),
            field("effect", STRING, mode=NULLABLE),
            field(
                "url",
                RECORD,
                mode=NULLABLE,
                fields=[
                    field(
                        "translation",
                        RECORD,
                        mode=REPEATED,
                        fields=[
                            field("text", STRING, mode=NULLABLE),
                            field("language", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field(
                "header_text",
                RECORD,
                mode=NULLABLE,
                fields=[
                    field(
                        "translation",
                        RECORD,
                        mode=REPEATED,
                        fields=[
                            field("text", STRING, mode=NULLABLE),
                            field("language", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field(
                "description_text",
                RECORD,
                mode=NULLABLE,
                fields=[
                    field(
                        "translation",
                        RECORD,
                        mode=REPEATED,
                        fields=[
                            field("text", STRING, mode=NULLABLE),
                            field("language", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field(
                "tts_header_text",
                RECORD,
                mode=NULLABLE,
                fields=[
                    field(
                        "translation",
                        RECORD,
                        mode=REPEATED,
                        fields=[
                            field("text", STRING, mode=NULLABLE),
                            field("language", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field(
                "tts_description_text",
                RECORD,
                mode=NULLABLE,
                fields=[
                    field(
                        "translation",
                        RECORD,
                        mode=REPEATED,
                        fields=[
                            field("text", STRING, mode=NULLABLE),
                            field("language", STRING, mode=NULLABLE),
                        ],
                    ),
                ],
            ),
            field("severityLevel", STRING, mode=NULLABLE),
        ],
    ),
]


def main(execution_date, **kwargs):
    client = bigquery.Client()
    hive_options = bigquery.external_config.HivePartitioningOptions()
    hive_options.mode = "AUTO"
    # TODO: do we want this for RT?
    # opt.require_partition_filter = True
    hive_options.source_uri_prefix = "gs://gtfs-data-test/service_alerts/"

    external_config = bigquery.ExternalConfig("NEWLINE_DELIMITED_JSON")
    external_config.source_uris = ["gs://gtfs-data-test/service_alerts/*.jsonl.gz"]
    external_config.autodetect = True
    external_config.ignore_unknown_values = True
    external_config.hive_partitioning = hive_options

    table = bigquery.Table(
        table_ref=bigquery.DatasetReference(get_project_id(), "gtfs_rt").table("external_service_alerts"),
        schema=SCHEMA,
    )
    table.external_data_configuration = external_config

    try:
        table = client.create_table(table)
    except Conflict:
        print("WARNING: got Conflict, dropping table and re-creating")
        client.delete_table(table)
        table = client.create_table(table)

    print(f"created table {table.full_table_id}")
