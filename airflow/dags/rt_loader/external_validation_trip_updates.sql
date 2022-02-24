---
operator: operators.SqlQueryOperator
dependencies:
    - load_rt_validations
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_trip_updates
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/validation/*/trip_updates.parquet"],
    format="PARQUET"
)
