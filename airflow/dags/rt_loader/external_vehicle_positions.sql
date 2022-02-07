---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_vehicle_positions
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.vehicle_positions`
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/vehicle_positions/*.jsonl.gz"]
)
