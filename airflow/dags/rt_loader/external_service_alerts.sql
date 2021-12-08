---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.service_alerts`
OPTIONS (
    format = "PARQUET",
    uris = ["gs://gtfs-data/rt-processed/service_alerts/*.parquet"]
)
