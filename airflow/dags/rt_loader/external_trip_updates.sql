---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_trip_updates
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.trip_updates` (
  calitp_itp_id INT64,
  calitp_url_number INT64,
  calitp_filepath STRING,
  id STRING,
  header STRUCT<
      timestamp INT64,
      incrementality STRING,
      gtfsRealtimeVersion STRING
    >,
  tripUpdate STRUCT <
    trip STRUCT <
      tripId STRING,
      routeId STRING,
      directionId INT64,
      startTime STRING,
      startDate STRING,
      scheduleRelationship STRING
      >,
    vehicle STRUCT <
      licensePlate STRING,
      label STRING,
      id STRING
      >,
    stopTimeUpdate ARRAY<
      STRUCT<
        stopSequence INT64,
        stopId STRING,
        arrival STRUCT <
          delay INT64,
          time INT64,
          uncertainty INT64
          >,
        departure STRUCT <
          delay INT64,
          time INT64,
          uncertainty INT64
          >,
        scheduleRelationship STRING
        >
      >,
    timestamp INT64,
    delay INT64
  >
)
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/trip_updates/*.jsonl.gz"],
    ignore_unknown_values = True
)
