{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT *
    FROM {{ ref('util_gtfs_schedule_v2_date_spine') }}
),

dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

urls_to_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
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
        t2.base64_url,
        urls_to_gtfs_datasets.gtfs_dataset_key AS gtfs_dataset_key,
        t1.date_day > CURRENT_DATE() AS is_future
    FROM make_noon_pacific AS t1
    INNER JOIN dim_schedule_feeds AS t2
        ON t1.noon_pacific BETWEEN t2._valid_from AND t2._valid_to
    LEFT JOIN urls_to_gtfs_datasets
        ON t2.base64_url = urls_to_gtfs_datasets.base64_url
        AND CAST(date_day AS TIMESTAMP) BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
)

SELECT * FROM fct_daily_schedule_feeds
