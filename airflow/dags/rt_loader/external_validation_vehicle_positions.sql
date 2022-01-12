---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_vehicle_positions (
    errorMessage STRUCT<
      messageId INT64,
      gtfsRTFeedIterationModel STRING,
      validationRule STRUCT<
        errorId STRING,
        severity STRING,
        title STRING,
        errorDescription STRING,
        occurrenceSuffix STRING
      >,
      errorDetails STRING
    >,
    occurrenceList ARRAY<
      STRUCT<
        occurrenceId INT64,
        messageLogModel STRING,
        prefix STRING
      >
    >
)
OPTIONS (
    uris=["gs://calitp-py-ci/gtfs-rt-validator-api/test_output_full/*gtfs_rt_vehicle_positions_url"],
    format="JSON"
)
