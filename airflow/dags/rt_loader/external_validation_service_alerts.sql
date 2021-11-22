---
operator: operators.SqlQueryOperator
description: |
  GTFS RT validation errors as returned by the validator. Each entry corresponds
  to a <filename>.results.json file that is spit out by the validator.
fields:
  errorMessage: |
    An object with fields for messageId, gtfsRTFeedIterationModel, validationRule,
    errorDetails.
  occurrenceList: |
    An array of objects with these fields: occurenceId, messageLogModel, prefix
---

CREATE OR REPLACE EXTERNAL TABLE gtfs_rt.validation_service_alerts (
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
    uris=["gs://calitp-py-ci/gtfs-rt-validator-api/test_output_full/*gtfs_rt_service_alerts_url"],
    format="JSON"
)
