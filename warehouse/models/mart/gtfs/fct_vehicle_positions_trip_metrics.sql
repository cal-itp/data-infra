{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH vehicle_positions AS (
    SELECT
        trip_instance_key,
        location_timestamp,
        location
    FROM {{ ref('fct_vehicle_locations') }}
    WHERE service_date = "2025-06-13"
    -- TODO: implementation note on filtering out timestamps after the last stop's likely arrival per trip
    -- https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/06_update_completeness_vp.ipynb
),

trips AS (
    SELECT DISTINCT
        trip_instance_key,
        shape_array_key
    FROM {{ ref('fct_scheduled_trips') }}
    --FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_scheduled_trips`
    WHERE service_date = "2025-06-13"
),

shapes AS (
    SELECT
        key,
        pt_array
    FROM {{ ref('dim_shapes_arrays') }}
    --FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_shapes_arrays`
    --INNER JOIN trips
      --ON key = trips.shape_array_key
),


vp_trip_summaries AS (
    SELECT
        *
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
    WHERE service_date = "2025-06-13"
    --AND trip_schedule_relationships = "SCHEDULED" adding this reduces the rows to 0
),

minute_bins AS (
    SELECT
        vehicle_positions.trip_instance_key,

        -- vp completeness metrics
        -- https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/06_update_completeness_vp.ipynb
        -- bin to 1 minute and count how many vehicle position rows there are
        -- there is difficulty in setting up schema similar to stop_time_updates since we haven't calculated
        -- where the vp is relative to stop
        EXTRACT(HOUR FROM DATETIME(location_timestamp, "America/Los_Angeles")) AS extract_hour,
        EXTRACT(MINUTE FROM DATETIME(location_timestamp, "America/Los_Angeles")) AS extract_minute,

        -- spatial accuracy metrics
        vehicle_positions.location,
        shapes.pt_array,

    FROM vehicle_positions
    -- use left joins because we want to count vp trips that don't join to any shape
    LEFT JOIN trips
        ON vehicle_positions.trip_instance_key = trips.trip_instance_key
    LEFT JOIN shapes
        ON trips.shape_array_key = shapes.key
),

derive_metrics AS (
    SELECT
        trip_instance_key,
        extract_hour,
        extract_minute,

        -- vp completeness metrics
        COUNT(*) AS vp_per_minute,
        CASE WHEN COUNT(*) >= 2 THEN 1
          ELSE 0
        END AS is_complete,

        -- spatial accuracy metrics

        COUNT(
            ST_DWITHIN(location, ST_MAKELINE(pt_array), 35, FALSE)
        ) AS n_within_shape, --numerator
        COUNT(*) AS n_vp, -- denominator

    FROM minute_bins
    GROUP BY trip_instance_key, extract_hour, extract_minute
),

vp_metrics AS (
    SELECT
        trip_instance_key,

        -- vp completeness metric
        SUM(is_complete) AS n_minutes_complete,
        ROUND(SUM(vp_per_minute) / COUNT(*), 2) AS avg_vp_per_minute,
        COUNT(*) AS vp_trip_minutes,

        -- spatial accuracy metric
        SUM(n_within_shape) AS n_within_shape,
        SUM(n_vp) AS n_vp,

    FROM derive_metrics
    GROUP BY trip_instance_key
),

fct_vehicle_positions_trip_metrics AS (
    SELECT
        vp_trip_summaries.*,

        vp_metrics.n_minutes_complete,
        vp_metrics.avg_vp_per_minute,
        vp_metrics.vp_trip_minutes,
        vp_metrics.n_vp,
        vp_metrics.n_within_shape,

    FROM vp_trip_summaries
    INNER JOIN vp_metrics USING (trip_instance_key)
)

SELECT * FROM fct_vehicle_positions_trip_metrics
