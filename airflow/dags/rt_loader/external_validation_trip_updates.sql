---
operator: operators.SqlQueryOperator
description: |
  GTFS RT validation errors as returned by the validator. Each row corresponds to
  the number of occurrences of a given error for a single itp_id/url/tick/entity combination.
fields:
  calitp_itp_id: |
    The ITP ID associated with the trip update.
  calitp_url_number: |
    The URL number associated with the trip update.
  calitp_extracted_at: |
    When the original file was downloaded.
  rt_feed_type: |
    The type of RT feed entity; will always be trip updates.
  error_id: |
    An error ID as defined in the GTFS RT validator repo.
  n_occurrences: |
    The number of occurrences of this error.
dependencies:
    - load_rt_validations
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_trip_updates
OPTIONS (
    uris=["{{get_bucket()}}/rt-processed/validation/*/trip_updates.parquet"],
    format="PARQUET"
)
