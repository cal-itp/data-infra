{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT *
    FROM {{ ref('util_gtfs_schedule_v2_date_spine') }}
),

dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

make_noon_pacific AS (
    SELECT
        date_day,
        TIMESTAMP_ADD(TIMESTAMP(date_day, "America/Los_Angeles"), INTERVAL 12 HOUR) AS noon_pacific
    FROM date_spine
),

fct_daily_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['t1.date_day', 't2.key']) }} AS key,
        t1.date_day AS date,
        t2.key AS feed_key,
        t3.key AS gtfs_dataset_key,
        t1.date_day > CURRENT_DATE() AS is_future
    FROM make_noon_pacific AS t1
    INNER JOIN dim_schedule_feeds AS t2
        ON t1.noon_pacific BETWEEN t2._valid_from AND t2._valid_to
    LEFT JOIN dim_gtfs_datasets AS t3
        ON t1.noon_pacific BETWEEN t3._valid_from AND t3._valid_to
            AND t2.base64_url = t3.base64_url
)

SELECT * FROM fct_daily_schedule_feeds
