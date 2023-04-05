{{ config(materialized='incremental', unique_key = 'key') }}

WITH int_transit_database__urls_to_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

fct_daily_schedule_feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

validation_map AS (
    SELECT *
    FROM {{ ref('bridge_schedule_dataset_for_validation') }}
),

parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

grouped_parse_outcomes AS (
    SELECT
        dt,
        base64_url,
        feed_type,
        CASE
            WHEN parse_success THEN "parse_success_file_count"
            ELSE "parse_failure_file_count"
        END AS aggregation_outcome,
        COUNT(*) as file_count
    FROM parse_outcomes
    -- this can be null if we failed to write metadata on the original extract
    -- for example gs://calitp-gtfs-rt-raw-v2/trip_updates/dt=2022-12-31/hour=2022-12-31T04:00:00+00:00/ts=2022-12-31T04:17:40+00:00/base64_url=aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1DTQ==/feed
    WHERE base64_url IS NOT NULL
    GROUP BY
        dt,
        base64_url,
        feed_type,
        parse_success
),

pivoted_parse_outcomes AS (
    SELECT
        dt,
        base64_url,
        feed_type,
        COALESCE(parse_success_file_count, 0) AS parse_success_file_count,
        COALESCE(parse_failure_file_count, 0) AS parse_failure_file_count,
    FROM grouped_parse_outcomes
    PIVOT(SUM(file_count) FOR aggregation_outcome IN ("parse_success_file_count", "parse_failure_file_count"))
),

fct_daily_rt_feed_files AS (
    SELECT
        parse.dt as date,
        {{ dbt_utils.generate_surrogate_key(['parse.dt', 'parse.base64_url']) }} AS key,
        parse.base64_url,
        parse.feed_type,
        parse.parse_success_file_count,
        parse.parse_failure_file_count,
        url_map.gtfs_dataset_key,
        validation_map.schedule_to_use_for_rt_validation_gtfs_dataset_key,
        schedule.feed_key AS schedule_feed_key
    FROM pivoted_parse_outcomes AS parse
    LEFT JOIN int_transit_database__urls_to_gtfs_datasets AS url_map
        ON parse.base64_url = url_map.base64_url
        AND CAST(parse.dt AS TIMESTAMP) BETWEEN url_map._valid_from AND url_map._valid_to
    LEFT JOIN dim_gtfs_datasets AS datasets
        ON url_map.gtfs_dataset_key = datasets.key
    LEFT JOIN validation_map
        ON url_map.gtfs_dataset_key = validation_map.gtfs_dataset_key
        AND CAST(parse.dt AS TIMESTAMP) BETWEEN validation_map._valid_from AND validation_map._valid_to
    LEFT JOIN fct_daily_schedule_feeds AS schedule
        ON validation_map.schedule_to_use_for_rt_validation_gtfs_dataset_key = schedule.gtfs_dataset_key
        AND parse.dt = schedule.date
)

SELECT * FROM fct_daily_rt_feed_files
