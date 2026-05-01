# TIDES validation harness

Local validator that exports a sample of a Cal-ITP TIDES table to parquet and runs Frictionless validation against the official TIDES JSON schema. Used to confirm Cal-ITP's TIDES output conforms to the open spec before publishing files to the public open-data bucket.

Lives outside the dbt project on purpose: this is a tooling concern, not a warehouse model.

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

Validate vehicle_locations for one service date in your sandbox:

```bash
python validate_tides.py \
  --dataset christopher_mart_gtfs \
  --table fct_tides_vehicle_locations \
  --schema <path-to-your-TIDES-clone>/spec/vehicle_locations.schema.json \
  --service-date 2026-04-30
```

The script:

1. Selects `* EXCEPT (Cal-ITP-internal columns)` from the BQ table for the given `service_date`.
2. Writes the result to `exports/<table>_<date>.parquet`.
3. Loads the TIDES JSON schema as a Frictionless `Schema`.
4. Runs `frictionless.validate()` against the parquet file.
5. Prints a human-readable report and writes `sample-report.txt`.

Exit code is 0 on validation success, 1 on failure.

## TIDES schemas

This validator points at TIDES schema files in the upstream spec repo (`https://github.com/TIDES-transit/TIDES`). Pass `--schema <path-to-your-TIDES-clone>/spec/<table>.schema.json`.

Currently supported schemas:

- `vehicle_locations.schema.json`
- `trips_performed.schema.json` (added in PR 3)

## What this catches

- Required-field NULL violations
- Type mismatches between BQ column types and TIDES `string`/`number`/`integer`/`date`/`datetime`
- Min/max constraint violations (lat/lon bounds, heading 0-360, speed >= 0, trip_stop_sequence >= 1)
- Enum membership violations (current_status, gps_quality, trip_type, schedule_relationship)
- Primary-key uniqueness on `location_ping_id` (vehicle_locations) and `(service_date, trip_id_performed)` (trips_performed)

## Future

- Wrap the export-and-validate flow in an Airflow DAG so each daily public-bucket parquet write is validated automatically (file follow-up issue once #4700 lands the public bucket).
- Add a Frictionless data-package descriptor that references both vehicle_locations.parquet and trips_performed.parquet so cross-table foreign-key checks (vehicle_locations.trip_id_performed → trips_performed.trip_id_performed) run as part of the validation.
- Hook into the dbt build via a `post-hook` on the TIDES models so every `dbt run` of TIDES output gets a validation pass.
