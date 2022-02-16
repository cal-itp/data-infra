---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_service_alerts
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.service_alerts`
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/service_alerts/*.jsonl.gz"],
    ignore_unknown_values = True
)
