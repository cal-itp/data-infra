---
operator: operators.SqlQueryOperator
dependencies:
    - load_rt_validations
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_service_alerts
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/validation/*/service_alerts.parquet"],
    format="PARQUET"
)
