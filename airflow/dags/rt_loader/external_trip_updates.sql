---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_trip_updates
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.trip_updates`
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/trip_updates/*.jsonl.gz"],
    ignore_unknown_values = True
)
