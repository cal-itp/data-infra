{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__routes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__routes') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__routes') }}
),

dim_routes AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'route_id']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        route_id,
        route_type,
        agency_id,
        route_short_name,
        route_long_name,
        route_desc,
        route_url,
        route_color,
        route_text_color,
        route_sort_order,
        continuous_pickup,
        continuous_drop_off,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_routes
