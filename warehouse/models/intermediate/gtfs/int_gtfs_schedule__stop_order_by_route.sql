{{
    config(
        materialized='table',
        cluster_by='feed_key'
    )
}}

WITH dim_stop_arrivals AS (
    SELECT *
    FROM {{ ref('dim_stop_arrivals') }}
),

dim_routes AS (
    SELECT
        feed_key,
        route_id,
        route_short_name,
        route_long_name
    FROM {{ ref('dim_routes') }}
),

daily_feeds AS (
    SELECT
        feed_key,
        base64_url,
        gtfs_dataset_key,
        gtfs_dataset_name,
        CAST(MIN(t1.date) AS DATE) AS _valid_from_service_date,
        CAST(MAX(t1.date) AS DATE) AS _valid_to_service_date,

    FROM {{ ref('fct_daily_schedule_feeds') }} AS t1
    GROUP BY 1, 2, 3, 4
),

ordered_stops AS (
    SELECT
        dim_stop_arrivals.feed_key,
        daily_feeds.base64_url,
        daily_feeds.gtfs_dataset_key,
        daily_feeds.gtfs_dataset_name,
        dim_stop_arrivals.route_id,
        dim_routes.route_short_name,
        dim_routes.route_long_name,
        dim_stop_arrivals.direction_id,
        {{ get_combined_route_name('daily_feeds.gtfs_dataset_name', 'dim_stop_arrivals.route_id',
            'dim_routes.route_short_name', 'dim_routes.route_long_name') }} AS route_name,
        stop_id,
        ROUND(AVG(stop_sequence), 1) AS avg_stop_seq,
        MIN(_valid_from_service_date) AS _valid_from_service_date,
        MAX(_valid_to_service_date) AS _valid_to_service_date

    FROM dim_stop_arrivals
    INNER JOIN dim_routes
        ON dim_stop_arrivals.feed_key = dim_routes.feed_key
        AND dim_stop_arrivals.route_id = dim_routes.route_id
    INNER JOIN daily_feeds
        ON dim_stop_arrivals.feed_key = daily_feeds.feed_key
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT * FROM ordered_stops
