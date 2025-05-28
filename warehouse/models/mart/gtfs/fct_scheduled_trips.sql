{{ config(
    materialized='table') }}
--fix config
WITH int_gtfs_schedule__daily_scheduled_service_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__daily_scheduled_service_index') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

dim_trips AS (
    SELECT *
    FROM {{ ref('dim_trips') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

dim_shapes_arrays AS (
    SELECT * FROM {{ ref('dim_shapes_arrays') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

stop_times_grouped AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
    WHERE feed_key in ("c8c998ed5280bd8afe6229f41075d602") 
),

-- use seed to fill in where shape_ids are missing
derived_shapes AS (
    SELECT *
    FROM {{ ref('gtfs_optional_shapes') }}
),

derived_shapes_with_feed AS (
    SELECT DISTINCT
        fct_daily_schedule_feeds.feed_key,
        derived_shapes.gtfs_dataset_name,
        derived_shapes.route_id,
        derived_shapes.direction_id,
        derived_shapes.shape_id

    FROM derived_shapes
    INNER JOIN fct_daily_schedule_feeds
        ON derived_shapes.gtfs_dataset_name = fct_daily_schedule_feeds.gtfs_dataset_name
),

dim_trips2 AS (
    SELECT 
        * EXCEPT(feed_key, route_id, direction_id, shape_id, key),
        dim_trips.key, --the key in dim_trips will have null shape_id, so somehow it's not carrying over in the join later
        dim_trips.feed_key,
        dim_trips.route_id,
        dim_trips.direction_id,
        COALESCE(dim_trips.shape_id, derived_shapes_with_feed.shape_id) AS shape_id,
    FROM dim_trips 
    LEFT JOIN derived_shapes_with_feed
        ON derived_shapes_with_feed.feed_key = dim_trips.feed_key
            AND derived_shapes_with_feed.route_id = dim_trips.route_id
            AND derived_shapes_with_feed.direction_id = dim_trips.direction_id
),

gtfs_joins AS (
    SELECT

        service_index.service_date,
        service_index.feed_key,
        trips.base64_url,
        service_index.service_id,
        service_index.feed_timezone,

        trips.key AS trip_key,
        trips.trip_id AS trip_id,
        trips.trip_short_name,
        trips.direction_id,
        trips.block_id,
        --stop_times_grouped.iteration_num,
        --stop_times_grouped.frequencies_defined_trip,

        routes.key AS route_key,
        routes.route_id AS route_id,
        routes.route_type,
        routes.route_short_name,
        routes.route_long_name,
        routes.route_desc,
        routes.agency_id AS agency_id,
        routes.network_id AS network_id,
        routes.continuous_pickup AS route_continuous_pickup,
        routes.continuous_drop_off AS route_continuous_drop_off,
        routes.route_color,
        routes.route_text_color,
        
        trips.shape_id,
        trips.warning_duplicate_gtfs_key AS contains_warning_duplicate_trip_primary_key,
        
        shapes.key AS shape_array_key,
        shapes.pt_array --# this attaches now
        
    FROM int_gtfs_schedule__daily_scheduled_service_index AS service_index
    INNER JOIN dim_trips2 AS trips
        ON service_index.feed_key = trips.feed_key
            AND service_index.service_id = trips.service_id
    LEFT JOIN dim_shapes_arrays as shapes
        ON service_index.feed_key = shapes.feed_key
            AND trips.shape_id = shapes.shape_id
    LEFT JOIN dim_routes AS routes
        ON service_index.feed_key = routes.feed_key
            AND trips.route_id = routes.route_id
),

gtfs_joins2 AS (
    SELECT
        
        gtfs_joins.*,
        stop_times_grouped.iteration_num,
        stop_times_grouped.frequencies_defined_trip,
    FROM gtfs_joins
    LEFT JOIN stop_times_grouped
        ON gtfs_joins.feed_key = stop_times_grouped.feed_key
            AND gtfs_joins.trip_id = stop_times_grouped.trip_id
    -- drop trips with no stops
    WHERE stop_times_grouped.feed_key IS NOT NULL
)

SELECT * FROM gtfs_joins2