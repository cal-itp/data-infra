# California TIDES Public Data

Cal-ITP publishes Transit Integrated Data Exchange Specification (TIDES) data
products generated from California GTFS-Realtime feeds. This staging bucket is
the predecessor of the eventual production bucket; data here is intended for
evaluation and is not yet authoritative.

The corresponding Airflow DAG is `publish_tides` (see
`airflow/dags/publish_tides.py`).

## What is published

- `tides/v1/vehicle_locations/gtfs_dataset_key=<key>/service_date=<date>/data*.parquet`

  TIDES vehicle_locations rows, partitioned by GTFS feed (`gtfs_dataset_key`)
  and service date, in Snappy-compressed parquet.

## Cadence

Monthly, on the 1st of each month at 00:00 UTC. Each run rewrites the entire
publishable history (see "Rollback" below).

## Schema

Conforms to the TIDES vehicle_locations specification:
https://github.com/TIDES-transit/TIDES/blob/main/spec/vehicle_locations.schema.json

## Access

Public read access via direct GCS HTTP. No authentication required.

Example: download all of one feed's data for April 2026:

```
gsutil -m cp -r \
  gs://calitp-tides-staging/tides/v1/vehicle_locations/gtfs_dataset_key=<KEY>/service_date=2026-04-*/ \
  ./
```

## Identifying agencies

`gtfs_dataset_key` is a stable identifier for the underlying GTFS-Realtime
feed. Some feeds serve multiple operating agencies. Resolve a key to a human
agency name and NTD ID via the bucket-root sidecar:

```
gs://calitp-tides-staging/_metadata.jsonl
```

This is a JSON Lines file with one record per active feed: `gtfs_dataset_key`,
`organization_name`, `organization_ntd_id`.

## Rollback

The publish job uses `EXPORT DATA OPTIONS(overwrite=true, ...)`. A bad
upstream run can overwrite the previous good output. For the staging bucket
this is acceptable; consumers should treat staging output as evaluation-grade
and not yet authoritative. A pre-overwrite validation gate is on the roadmap
before production cutover.

If you discover a bad export, file an issue (below) and Cal-ITP can restore
from BigQuery time travel against the upstream view.

## Issues and contact

File issues at https://github.com/cal-itp/data-infra/issues.
