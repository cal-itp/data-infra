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

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

dim_shapes_arrays AS (
    SELECT * FROM {{ ref('dim_shapes_arrays') }}
),

urls_to_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

stop_times_grouped AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
),

fct_daily_scheduled_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key(['service_index.service_date', 'trips.key']) }} AS key,
        service_index.service_date,
        service_index.feed_key,
        service_index.service_id,

        trips.key AS trip_key,
        trips.trip_id AS trip_id,

        routes.key AS route_key,
        routes.route_id AS route_id,

        shapes.key AS shape_array_key,
        urls_to_gtfs_datasets.gtfs_dataset_key AS gtfs_dataset_key,
        trips.warning_duplicate_primary_key AS contains_warning_duplicate_trip_primary_key,

        stop_times_grouped.n_stops,
        stop_times_grouped.n_stop_times,
        stop_times_grouped.trip_first_departure_sec,
        stop_times_grouped.trip_last_arrival_sec,
        stop_times_grouped.service_hours,
        stop_times_grouped.contains_warning_duplicate_primary_key AS contains_warning_duplicate_stop_times_primary_key,
        stop_times_grouped.contains_warning_missing_foreign_key_stop_id

    FROM int_gtfs_schedule__daily_scheduled_service_index AS service_index
    INNER JOIN dim_trips AS trips
        ON service_index.feed_key = trips.feed_key
            AND service_index.service_id = trips.service_id
    LEFT JOIN dim_routes AS routes
        ON service_index.feed_key = routes.feed_key
            AND trips.route_id = routes.route_id
    LEFT JOIN dim_shapes_arrays AS shapes
        ON service_index.feed_key = shapes.feed_key
            AND trips.shape_id = shapes.shape_id
    LEFT JOIN dim_schedule_feeds AS feeds
        ON service_index.feed_key = feeds.key
    LEFT JOIN urls_to_gtfs_datasets
        ON feeds.base64_url = urls_to_gtfs_datasets.base64_url
    LEFT JOIN stop_times_grouped
        ON service_index.feed_key = stop_times_grouped.feed_key
            AND trips.trip_id = stop_times_grouped.trip_id
)

SELECT * FROM fct_daily_scheduled_trips
