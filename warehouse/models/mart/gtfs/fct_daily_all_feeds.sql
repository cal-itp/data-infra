WITH

schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

rt_feeds AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

fct_daily_all_feeds AS (
    SELECT
        date,
        feed_key,
        gtfs_dataset_key,
        "schedule" AS feed_type,
    FROM schedule_feeds

    UNION ALL

    SELECT
        date,
        feed_key,
        gtfs_dataset_key,
        feed_type,
    FROM rt_feeds
)

SELECT * FROM fct_daily_all_feeds
