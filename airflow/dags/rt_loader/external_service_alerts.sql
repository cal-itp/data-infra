---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.service_alerts`
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/service_alerts/*.gz"]
)
