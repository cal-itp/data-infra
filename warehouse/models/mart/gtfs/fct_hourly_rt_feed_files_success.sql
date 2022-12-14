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
),

int_gtfs_rt__unioned_parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
),

int_transit_database__urls_to_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

parse_outcomes AS (
    SELECT *
    FROM int_gtfs_rt__unioned_parse_outcomes
    {% if is_incremental() %}
    WHERE dt >= DATE '{{ max_date }}'
    {% else %}
        WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

daily_totals AS (

    SELECT

        dt,
        base64_url,
        feed_type,
        COUNT(*) AS file_count_day,
        (
            SUM(CASE parse_success WHEN TRUE THEN 1 ELSE 0 END) / COUNT(*)
        ) AS prop_success_file_count_day

    FROM parse_outcomes
    GROUP BY
        dt,
        base64_url,
        feed_type

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

        pivot_hourly_totals.* EXCEPT (dt, base64_url, feed_type),

        url_map.gtfs_dataset_key

    FROM int_gtfs_rt__daily_url_index AS url_index
    LEFT JOIN pivot_hourly_totals
        ON url_index.dt = pivot_hourly_totals.dt
            AND url_index.base64_url = pivot_hourly_totals.base64_url
            AND url_index.type = pivot_hourly_totals.feed_type
    LEFT JOIN daily_totals
        ON url_index.dt = daily_totals.dt
            AND url_index.base64_url = daily_totals.base64_url
            AND url_index.type = daily_totals.feed_type
    LEFT JOIN int_transit_database__urls_to_gtfs_datasets AS url_map
        ON url_index.base64_url = url_map.base64_url

)

SELECT * FROM fct_hourly_rt_feed_files_success
