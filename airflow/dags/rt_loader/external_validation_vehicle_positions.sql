---
operator: operators.SqlQueryOperator
dependencies:
    - load_rt_validations
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_vehicle_positions
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/validation/*/vehicle_positions.parquet"],
    format="PARQUET"
)
