{{ config(materialized='incremental', unique_key = 'key') }}

WITH

int_gtfs_rt__daily_url_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__daily_url_index') }}
    WHERE data_quality_pipeline
        AND {{ gtfs_rt_dt_where() }}
),

fct_daily_rt_feed_files AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_feed_files') }}
),

parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

daily_totals AS (

    SELECT

        date AS dt,
        base64_url,
        feed_type,
        gtfs_dataset_key,

        parse_success_file_count / (parse_success_file_count + parse_failure_file_count) AS prop_success_file_count_day

    FROM fct_daily_rt_feed_files

),

hourly_totals AS (

    SELECT

        dt,
        base64_url,
        feed_type,
        EXTRACT(HOUR FROM hour) AS download_hour,
        SUM(
            CASE parse_success WHEN TRUE THEN 1 ELSE 0 END
        ) AS success_file_count_hour,
        COUNT(*) AS file_count_hour

    FROM parse_outcomes
    GROUP BY
        dt,
        download_hour,
        base64_url,
        feed_type

),

pivot_hourly_totals AS (

    SELECT *
    FROM
        (SELECT

            dt,
            download_hour,
            base64_url,
            feed_type,
            (success_file_count_hour / file_count_hour) AS prop_success_hour

            FROM hourly_totals)
    PIVOT(
        MAX(prop_success_hour) AS hr
        FOR download_hour IN
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15, 16, 17, 18, 19,
            20, 21, 22, 23)
    )
),

fct_hourly_rt_feed_files_success AS (
    SELECT

        {{ farm_surrogate_key(['url_index.dt', 'url_index.base64_url']) }} AS key,

        url_index.dt,
        url_index.base64_url,
        url_index.type AS feed_type,

        daily_totals.prop_success_file_count_day,
        daily_totals.gtfs_dataset_key,

        pivot_hourly_totals.* EXCEPT (dt, base64_url, feed_type)

    FROM int_gtfs_rt__daily_url_index AS url_index
    LEFT JOIN pivot_hourly_totals
        ON url_index.dt = pivot_hourly_totals.dt
            AND url_index.base64_url = pivot_hourly_totals.base64_url
    LEFT JOIN daily_totals
        ON url_index.dt = daily_totals.dt
            AND url_index.base64_url = daily_totals.base64_url

)

SELECT * FROM fct_hourly_rt_feed_files_success
