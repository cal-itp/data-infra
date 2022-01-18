---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.trip_updates`
OPTIONS (
    format = "PARQUET",
    uris = ["{{get_bucket()}}/rt-processed/trip_updates/*.parquet"]
)
