{{ config(materialized='table') }}

WITH

schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

rt_feeds AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

unioned AS (
    SELECT
        date,
        feed_key,
        null AS schedule_feed_key,
        gtfs_dataset_key,
        'schedule' AS feed_type,
    FROM schedule_feeds

    UNION ALL

    SELECT
        date,
        null AS feed_key,
        schedule_feed_key,
        gtfs_dataset_key,
        feed_type,
    FROM rt_feeds
),

fct_daily_all_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'gtfs_dataset_key']) }} AS key,
        *,
    FROM unioned
)

SELECT * FROM fct_daily_all_feeds
