{{ config(materialized='table') }}

WITH validation_service_alerts AS (
    SELECT *
    FROM {{ source('gtfs_rt_raw','validation_service_alerts') }}
),

validation_trip_updates AS (
    SELECT *
    FROM {{ source('gtfs_rt_raw','validation_trip_updates') }}
),

validation_vehicle_positions AS (
    SELECT *
    FROM {{ source('gtfs_rt_raw','validation_vehicle_positions') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

unioned AS (
    SELECT *
    FROM validation_service_alerts
    UNION ALL
    SELECT *
    FROM validation_trip_updates
    UNION ALL
    SELECT *
    FROM validation_vehicle_positions
),

error_counts AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        rt_feed_type,
        error_id,
        DATE(calitp_extracted_at) AS date,
        SUM(n_occurrences) AS occurrences
    FROM unioned
    GROUP BY
        calitp_itp_id,
        calitp_url_number,
        rt_feed_type,
        error_id,
        date
),
-- join with schedule dim feeds to get feed key
-- note that this matching is imperfect; the schedule that is used for validation
-- is actually pulled from gtfs_schedule_history.calitp_feed_status

gtfs_rt_fact_daily_validation_errors AS (
    SELECT
        t1.*,
        t2.feed_key
    FROM error_counts AS t1
    LEFT JOIN gtfs_schedule_dim_feeds AS t2
        ON t1.date >= t2.calitp_extracted_at
            AND t1.date < t2.calitp_deleted_at
            AND t1.calitp_itp_id = t2.calitp_itp_id
            AND t1.calitp_url_number = t2.calitp_url_number
)

SELECT * FROM gtfs_rt_fact_daily_validation_errors
