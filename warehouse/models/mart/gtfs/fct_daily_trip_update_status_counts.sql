{{ config(materialized='table') }}

WITH

fct_stop_time_updates AS (
    SELECT * FROM {{ ref('fct_stop_time_updates') }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)
),

fct_daily_trip_update_status_counts AS (
    SELECT
        dt,
        base64_url,
        gtfs_dataset_key,
        trip_schedule_relationship,
        COUNT(distinct trip_id) AS distinct_trip_ids,
    FROM fct_stop_time_updates
    GROUP BY 1, 2, 3, 4
)

SELECT * FROM fct_daily_trip_update_status_counts
