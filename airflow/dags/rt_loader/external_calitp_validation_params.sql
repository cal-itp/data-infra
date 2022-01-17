---
operator: operators.SqlQueryOperator
description: |
  Parameters passed to GTFS RT validation.
fields:
  calitp_itp_id: Internal ITP ID.
  calitp_url_number: Internal URL number.
  gtfs_schedule_path: Path to GTFS Schedule data used in validation.
  gtfs_rt_glob_path: |
    Path to GTFS RT data used in validation. Wildcards (*) allow the path to grab
    every individual RT file we store.
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_service_alerts (
    calitp_itp_id INT64,
    calitp_url_number INT64,
    calitp_extracted_at DATE,
    gtfs_schedule_path STRING,
    gtfs_rt_glob_path STRING
)
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/calitp_validation_params/*"],
    format="JSON"
)
