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
    FROM {{ ref('fct_vehicle_locations') }}
),

vp_trip_summaries AS (
    SELECT
        *
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

minute_bins AS (
    SELECT
        vehicle_positions.*,
        EXTRACT(HOUR FROM DATETIME(location_timestamp, "America/Los_Angeles")) AS extract_hour,
        EXTRACT(MINUTE FROM DATETIME(location_timestamp, "America/Los_Angeles")) AS extract_minute,
    FROM vehicle_positions
),

derive_metrics AS (
    SELECT
        trip_instance_key,
        extract_hour,
        extract_minute,

        COUNT(*) AS vp_per_minute,
        CASE WHEN COUNT(*) >= 2 THEN 1
          ELSE 0
        END AS is_complete

    FROM minute_bins
    GROUP BY trip_instance_key, extract_hour, extract_minute
),

vp_metrics AS (
    SELECT
        trip_instance_key,

        SUM(is_complete) AS n_minutes_complete,
        ROUND(SUM(vp_per_minute) / COUNT(*), 2) AS avg_vp_per_minute,
        SUM(vp_per_minute) AS n_vp,
        COUNT(*) AS vp_trip_minutes,

    FROM derive_metrics
    GROUP BY trip_instance_key
),

fct_vehicle_positions_trip_metrics AS (
    SELECT
        vp_trip_summaries.*,

        vp_metrics.n_minutes_complete,
        vp_metrics.avg_vp_per_minute,
        vp_metrics.n_vp,
        vp_metrics.vp_trip_minutes,
    FROM vp_trip_summaries
    INNER JOIN vp_metrics USING (trip_instance_key)
)

SELECT * FROM fct_vehicle_positions_trip_metrics
