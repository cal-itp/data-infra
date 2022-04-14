{{ config(materialized='table') }}

WITH gtfs_schedule_dim_routes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_routes') }}
),
gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
),
feed_routes AS (
    SELECT
    T1.feed_key
    , T2.route_key
    , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM gtfs_schedule_dim_feeds T1
    JOIN gtfs_schedule_dim_routes T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
),
gtfs_schedule_fact_daily_feed_routes AS (
    SELECT
        T1.feed_key
        , T1.route_key
        , T2.full_date AS date
        , T1.* EXCEPT(feed_key, route_key)
    FROM feed_routes T1
    JOIN dim_date T2
        ON  T1.calitp_extracted_at <= T2.full_date
            AND T1.calitp_deleted_at > T2.full_date
    WHERE T2.full_date <= CURRENT_DATE()
)

SELECT * FROM gtfs_schedule_fact_daily_feed_routes
