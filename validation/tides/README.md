# TIDES validation harness

Local validator that exports one feed's slice of a Cal-ITP TIDES table to parquet, runs Frictionless validation against the official TIDES JSON schema, and writes a JSON Lines outcome record. Used to confirm Cal-ITP's TIDES output conforms to the open spec before publishing files to the public open-data bucket.

The same logic is wrapped as the `ValidateTIDESToGCSOperator` Airflow operator so the DAG run produces outcome rows that can be loaded into BigQuery as an external table for monitoring.

Lives outside the dbt project on purpose: this is a tooling concern, not a warehouse model.

## Prerequisites

The validator needs a local clone of the upstream TIDES spec repo so it can read the JSON schema files. Clone it anywhere (a sibling to `data-infra/` is fine):

```bash
git clone https://github.com/TIDES-transit/TIDES.git
```

The `--schema` flag below points at the schema file inside that clone. The schemas currently used live at `<TIDES-clone>/spec/vehicle_locations.schema.json` and `<TIDES-clone>/spec/trips_performed.schema.json`. The harness is pinned to the `main` branch of the spec; bump the clone with `git pull` to pick up newer schema versions.

## Setup

```bash
cd validation/tides
uv sync
```

`uv sync` reads `pyproject.toml` (and `uv.lock` if present) and creates a `.venv/` in this directory.

## Usage

Validate vehicle_locations for one (service date, feed) in your sandbox:

```bash
uv run validate_tides.py \
  --dataset christopher_mart_tides \
  --table fct_tides_vehicle_locations \
  --schema <path-to-your-TIDES-clone>/spec/vehicle_locations.schema.json \
  --service-date 2026-04-30 \
  --gtfs-dataset-key 9edf45e373638700ca420b1e588efdaf \
  --feed-name "Beach Cities Transit" \
  --feed-url "warehouse://mart_tides/fct_tides_vehicle_locations/9edf45e373638700ca420b1e588efdaf"
```

The script:

1. Selects `* EXCEPT (Cal-ITP-internal columns)` from the BQ table for one `(service_date, gtfs_dataset_key)` pair.
2. Writes the result to `exports/<table>_<date>_<key>.parquet`.
3. Loads the TIDES JSON schema as a Frictionless `Schema`.
4. Runs `frictionless.validate()` against the parquet file.
5. Writes a JSON Lines outcome record to `exports/validate_<base64-of-feed-url>.jsonl` (override with `--outcome-output`).

Exit code is 0 on validation success, 1 on failure.

## Outcome record shape

Each outcome line is one JSON object with eight top-level fields, mirroring the GTFS pipeline outcome envelope (`download_parse_and_validate_gtfs.py`):

```jsonc
{
  "success": true,
  "exception": null,
  "step": "validate",
  "extract": {
    "filename": "<base64-of-feed-url>",
    "ts": "2026-05-05T03:00:00.888426+00:00",
    "config": {
      "feed_type": "tides_vehicle_locations",
      "name": "Beach Cities Transit",
      "url": "...",
      "service_date": "2026-04-30",
      "gtfs_dataset_key": "9edf45e373638700ca420b1e588efdaf",
      "warehouse_table": "fct_tides_vehicle_locations",
      "tides_schema_url": "..."
    },
    "response_code": null,
    "response_headers": null
  },
  "header": {
    "row_count": 12345,
    "feed_count": 1,
    "first_event_timestamp": "2026-04-30T00:00:11",
    "last_event_timestamp": "2026-04-30T23:59:48",
    "frictionless_valid": true,
    "error_counts_by_type": {}
  },
  "aggregation": {
    "filename": "validate_<base64-of-feed-url>.jsonl.gz",
    "step": "validate",
    "first_extract": { ...recursive copy of extract... }
  },
  "blob_path": "gs://calitp-tides-staging/validation_outcomes/dt=.../ts=.../base64_url=.../validate_<base64>.jsonl.gz",
  "process_stderr": null
}
```

The `aggregation.filename` and the destination blob name both embed the base64 of the feed URL, matching the join-key convention used across the GTFS pipeline.

## Library entry point

`run_validation(...)` returns the outcome dict directly. The `ValidateTIDESToGCSOperator` calls it that way and uploads the gzipped JSONL to GCS itself.

## TIDES schemas

Currently supported schemas (under `<TIDES-clone>/spec/`):

- `vehicle_locations.schema.json`
- `trips_performed.schema.json`

## What this catches

- Required-field NULL violations
- Type mismatches between BQ column types and TIDES `string` / `number` / `integer` / `date` / `datetime`
- Min/max constraint violations (lat/lon bounds, heading 0-360, speed >= 0, trip_stop_sequence >= 1)
- Enum membership violations (current_status, gps_quality, trip_type, schedule_relationship)
- Primary-key uniqueness on `location_ping_id` (vehicle_locations) and `(service_date, trip_id_performed)` (trips_performed)
