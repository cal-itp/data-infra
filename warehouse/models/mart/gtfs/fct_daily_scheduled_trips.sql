{{ config(materialized='table') }}

WITH int_gtfs_schedule__daily_scheduled_service_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__daily_scheduled_service_index') }}
),

dim_trips AS (
    SELECT *
    FROM {{ ref('dim_trips') }}
),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
),

fct_daily_scheduled_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key(['t1.service_date', 't2.key']) }} as key,
        t1.service_date,
        t1.feed_key,
        t1.service_id,
        t2.key AS trip_key,
        t3.key AS route_key,
        t2.warning_duplicate_primary_key AS warning_duplicate_trip_primary_key
    FROM int_gtfs_schedule__daily_scheduled_service_index AS t1
    LEFT JOIN dim_trips AS t2
        ON t1.feed_key = t2.feed_key
        AND t1.service_id = t2.service_id
    LEFT JOIN dim_routes AS t3
        ON t1.feed_key = t3.feed_key
        AND t2.route_id = t3.route_id
)

SELECT * FROM fct_daily_scheduled_trips
