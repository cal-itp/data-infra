---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_service_alerts
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.service_alerts` (
  calitp_itp_id INT64,
  calitp_url_number INT64,
  calitp_filepath STRING,
  id STRING,
  header STRUCT<
    timestamp INT64,
    incrementality STRING,
    gtfsRealtimeVersion STRING
  >,
  activePeriod STRUCT<
    start INT64,
    -- end is a reserved keyword but it's the name of the field
    -- escape with backticks
    `end` INT64
    >,
  informedEntity STRUCT <
    agencyId STRING,
    routeId STRING,
    routeType INT64,
    directionId INT64,
    trip STRUCT <
        tripId STRING,
        routeId STRING,
        directionId INT64,
        startTime STRING,
        startDate STRING,
        scheduleRelationship STRING
      >,
    stopId STRING
    >,
  cause STRING,
  effect STRING,
  url STRUCT <
    translation ARRAY<
      STRUCT<
        text STRING,
        language STRING
        >
      >
    >,
  header_text STRUCT <
    translation ARRAY<
      STRUCT<
        text STRING,
        language STRING
        >
      >
    >,
  description_text STRUCT <
    translation ARRAY<
      STRUCT<
        text STRING,
        language STRING
        >
      >
    >,
  tts_header_text STRUCT <
    translation ARRAY<
      STRUCT<
        text STRING,
        language STRING
        >
      >
    >,
  tts_description_text STRUCT <
    translation ARRAY<
      STRUCT<
        text STRING,
        language STRING
        >
      >
    >,
  severityLevel STRING
)
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/service_alerts/*.jsonl.gz"],
    ignore_unknown_values = True
)
