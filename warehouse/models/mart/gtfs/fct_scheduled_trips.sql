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
        COALESCE(dim_trips.shape_id, derived_shapes_with_feed.shape_id) AS shape_id
    FROM dim_trips
    LEFT JOIN derived_shapes_with_feed
        ON derived_shapes_with_feed.feed_key = dim_trips.feed_key
            AND derived_shapes_with_feed.route_id = dim_trips.route_id
            AND derived_shapes_with_feed.direction_id = dim_trips.direction_id
)


SELECT * FROM dim_trips2
