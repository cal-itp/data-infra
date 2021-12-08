---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.trip_updates`
OPTIONS (
    format = "PARQUET",
    uris = ["gs://gtfs-data/rt-processed/trip_updates/*.parquet"]
)
