---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.vehicle_positions`
OPTIONS (
    format = "PARQUET",
    uris = ["gs://gtfs-data/rt-processed/vehicle_positions/*.parquet"]
)
