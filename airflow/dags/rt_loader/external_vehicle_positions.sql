---
operator: operators.SqlQueryOperator

dependencies:
  - parse_rt_vehicle_positions
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.vehicle_positions` (
    calitp_itp_id INT64,
    calitp_url_number INT64,
    calitp_filepath STRING,
    id STRING,
    header STRUCT<
      timestamp INT64,
      incrementality STRING,
      gtfsRealtimeVersion STRING
    >,
    vehicle STRUCT<
      vehicle STRUCT <
        licensePlate STRING,
        label STRING,
        id STRING
      >,
      trip STRUCT <
        tripId STRING,
        routeId STRING,
        directionId INT64,
        startTime STRING,
        startDate STRING,
        scheduleRelationship STRING
      >,
      position STRUCT <
        latitude FLOAT64,
        longitude FLOAT64,
        bearing FLOAT64,
        odometer FLOAT64,
        speed FLOAT64
      >,
      currentStopSequence INT64,
      stopId STRING,
      currentStatus STRING,
      timestamp INT64,
      congestionLevel STRING,
      occupancyStatus STRING,
      occupancyPercentage INT64
    >
)
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/rt-processed/vehicle_positions/*.jsonl.gz"],
    ignore_unknown_values = True
)
