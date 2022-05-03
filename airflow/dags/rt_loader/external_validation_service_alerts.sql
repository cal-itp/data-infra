---
operator: operators.SqlQueryOperator

description: |
  GTFS RT validation errors as returned by the validator. Each row corresponds to
  the number of occurrences of a given error for a single itp_id/url/tick/entity combination.
fields:
  calitp_itp_id: |
    The ITP ID associated with the service alert.
  calitp_url_number: |
    The URL number associated with the service alert.
  calitp_extracted_at: |
    When the original file was downloaded.
  rt_feed_type: |
    The type of RT feed entity; will always be service alerts.
  error_id: |
    An error ID as defined in the GTFS RT validator repo.
  n_occurrences: |
    The number of occurrences of this error.

post_hooks:
    - "select calitp_itp_id from gtfs_rt.validation_service_alerts limit 1"

dependencies:
    - load_rt_validations
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_service_alerts
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/validation/*/service_alerts.parquet"],
    format="PARQUET"
)
