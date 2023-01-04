{{ config(materialized='incremental', unique_key = 'key') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max date in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_date = dates[0] %}
{% endif %}

WITH

int_gtfs_rt__daily_url_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__daily_url_index') }}
    {% if is_incremental() %}
    WHERE dt >= DATE '{{ max_date }}'
        AND data_quality_pipeline
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
        AND data_quality_pipeline
    {% endif %}
),

fct_daily_rt_feed_files AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_feed_files') }}
),

parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= DATE '{{ max_date }}'
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

daily_totals AS (

    SELECT

        date AS dt,
        base64_url,
        feed_type,
        gtfs_dataset_key,

        parse_success_file_count + parse_failure_file_count AS file_count_day

    FROM fct_daily_rt_feed_files

),

pivot_hourly_totals AS (

    SELECT *
    FROM
        (SELECT

            dt,
            EXTRACT(HOUR FROM hour) as download_hour,
            base64_url,
            feed_type,

        FROM parse_outcomes)
    PIVOT(
        COUNT(*) AS hr
        FOR download_hour IN
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15, 16, 17, 18, 19,
            20, 21, 22, 23)
    )
),

fct_hourly_rt_feed_files AS (
    SELECT

        {{ farm_surrogate_key(['url_index.dt', 'url_index.base64_url']) }} AS key,

        url_index.dt,
        url_index.base64_url,
        url_index.type AS feed_type,

        daily_totals.file_count_day,
        daily_totals.gtfs_dataset_key,

        pivot_hourly_totals.* EXCEPT (dt, base64_url, feed_type),

    FROM int_gtfs_rt__daily_url_index AS url_index
    LEFT JOIN pivot_hourly_totals
        ON url_index.dt = pivot_hourly_totals.dt
            AND url_index.base64_url = pivot_hourly_totals.base64_url
    LEFT JOIN daily_totals
        ON url_index.dt = daily_totals.dt
            AND url_index.base64_url = daily_totals.base64_url

)

SELECT * FROM fct_hourly_rt_feed_files
