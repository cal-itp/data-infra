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
        {{ dbt_utils.surrogate_key(['service_index.service_date', 'trips.key']) }} as key,
        service_index.service_date,
        service_index.feed_key,
        service_index.service_id,
        trips.key AS trip_key,
        routes.key AS route_key,
        trips.warning_duplicate_primary_key AS warning_duplicate_trip_primary_key
    FROM int_gtfs_schedule__daily_scheduled_service_index AS service_index
    LEFT JOIN dim_trips AS trips
        ON service_index.feed_key = trips.feed_key
        AND service_index.service_id = trips.service_id
    LEFT JOIN dim_routes AS routes
        ON service_index.feed_key = routes.feed_key
        AND trips.route_id = routes.route_id
)

SELECT * FROM fct_daily_scheduled_trips
