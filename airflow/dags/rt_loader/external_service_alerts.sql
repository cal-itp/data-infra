---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.service_alerts`
OPTIONS (
    format = "PARQUET",
    uris = ["{{get_bucket()}}/rt-processed/service_alerts/*.parquet"]
)
