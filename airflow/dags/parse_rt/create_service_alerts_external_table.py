# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - parse_rt_service_alerts
# ---
import json
import tempfile
import pandas as pd

from calitp import query_sql, save_to_gcfs, get_engine
from calitp.config import get_bucket

SERVICE_ALERTS_SCHEMA = [
  {
    "name": "calitp_itp_id",
    "type": "INTEGER"
  },
  {
    "name": "calitp_url_number",
    "type": "INTEGER"
  },
  {
    "name": "calitp_filepath",
    "type": "STRING"
  },
  {
    "name": "id",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "name": "timestamp",
        "type": "INTEGER"
      },
      {
        "name": "incrementality",
        "type": "STRING"
      },
      {
        "name": "gtfsRealtimeVersion",
        "type": "STRING"
      }
    ],
    "name": "header",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "name": "start",
        "type": "INTEGER"
      },
      {
        "name": "end",
        "type": "INTEGER"
      }
    ],
    "name": "activePeriod",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "name": "agencyId",
        "type": "STRING"
      },
      {
        "name": "routeId",
        "type": "STRING"
      },
      {
        "name": "routeType",
        "type": "INTEGER"
      },
      {
        "name": "directionId",
        "type": "INTEGER"
      },
      {
        "fields": [
          {
            "name": "tripId",
            "type": "STRING"
          },
          {
            "name": "routeId",
            "type": "STRING"
          },
          {
            "name": "directionId",
            "type": "INTEGER"
          },
          {
            "name": "startTime",
            "type": "STRING"
          },
          {
            "name": "startDate",
            "type": "STRING"
          },
          {
            "name": "scheduleRelationship",
            "type": "STRING"
          }
        ],
        "name": "trip",
        "type": "RECORD"
      },
      {
        "name": "stopId",
        "type": "STRING"
      }
    ],
    "name": "informedEntity",
    "type": "RECORD"
  },
  {
    "name": "cause",
    "type": "STRING"
  },
  {
    "name": "effect",
    "type": "STRING"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "name": "text",
            "type": "STRING"
          },
          {
            "name": "language",
            "type": "STRING"
          }
        ],
        "mode": "REPEATED",
        "name": "translation",
        "type": "RECORD"
      }
    ],
    "name": "url",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "name": "text",
            "type": "STRING"
          },
          {
            "name": "language",
            "type": "STRING"
          }
        ],
        "mode": "REPEATED",
        "name": "translation",
        "type": "RECORD"
      }
    ],
    "name": "header_text",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "name": "text",
            "type": "STRING"
          },
          {
            "name": "language",
            "type": "STRING"
          }
        ],
        "mode": "REPEATED",
        "name": "translation",
        "type": "RECORD"
      }
    ],
    "name": "description_text",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "name": "text",
            "type": "STRING"
          },
          {
            "name": "language",
            "type": "STRING"
          }
        ],
        "mode": "REPEATED",
        "name": "translation",
        "type": "RECORD"
      }
    ],
    "name": "tts_header_text",
    "type": "RECORD"
  },
  {
    "fields": [
      {
        "fields": [
          {
            "name": "text",
            "type": "STRING"
          },
          {
            "name": "language",
            "type": "STRING"
          }
        ],
        "mode": "REPEATED",
        "name": "translation",
        "type": "RECORD"
      }
    ],
    "name": "tts_description_text",
    "type": "RECORD"
  },
  {
    "name": "severityLevel",
    "type": "STRING"
  }
]


def main(execution_date, **kwargs):
    engine = get_engine()

    with tempfile.TemporaryDirectory() as tmpdir:
        schema_fname = os.path.join(tmpdir, "external_def")
        with open(schema_fname, "w") as f:
            json.dump(SERVICE_ALERTS_SCHEMA, f)
        subprocess.run([]).check_returncode()

    raw_params = query_sql(
        f"""
        SELECT
            calitp_itp_id,
            calitp_url_number,
            calitp_extracted_at
        FROM gtfs_schedule_history.calitp_feed_status
        WHERE
            is_extract_success
            AND NOT is_parse_error
            AND calitp_extracted_at = "{date_string}"
        """,
        as_df=True,
    )

    # Note that raw RT data is currently stored in the production bucket,
    # and not copied to the staging bucket
    prefix_path_schedule = f"{get_bucket()}/schedule/{execution_date}"

    # This prefix limits the validation to only 1 hour of data currently
    prefix_path_rt = f"gtfs-data/rt/{date_string}T00:*"

    raw_params["entity"] = [
        ("service_alerts", "trip_updates", "vehicle_positions")
    ] * len(raw_params)
    params = raw_params.explode("entity").reset_index(drop=True)

    params = pd.concat(
        [
            params,
            params.apply(
                lambda row: {
                    "gtfs_schedule_path": f"{prefix_path_schedule}/{row.calitp_itp_id}_{row.calitp_url_number}",
                    "gtfs_rt_glob_path": f"{prefix_path_rt}/{row.calitp_itp_id}/{row.calitp_url_number}/*{row.entity}*",
                    "output_filename": row.entity,
                },
                axis="columns",
                result_type="expand",
            ),
        ],
        axis="columns",
    )

    path = f"rt-processed/calitp_validation_params/{date_string}.csv"
    print(f"saving {params.shape[0]} validation params to {path}")
    save_to_gcfs(
        params.to_csv(index=False).encode(),
        path,
        use_pipe=True,
    )
