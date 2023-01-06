{{ config(materialized='incremental', unique_key = 'key') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max date in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='date', order_by = 'date DESC', max_records = 1) %}
    {% set max_date = dates[0] %}
{% endif %}

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

parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= DATE '{{ max_date }}'
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
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
        {{ dbt_utils.surrogate_key(['parse.dt', 'parse.base64_url']) }} AS key,
        parse.base64_url,
        parse.feed_type,
        parse.parse_success_file_count,
        parse.parse_failure_file_count,
        url_map.gtfs_dataset_key,
        datasets.schedule_to_use_for_rt_validation_gtfs_dataset_key,
        schedule.feed_key AS schedule_feed_key
    FROM pivoted_parse_outcomes AS parse
    LEFT JOIN int_transit_database__urls_to_gtfs_datasets AS url_map
        ON parse.base64_url = url_map.base64_url
    LEFT JOIN dim_gtfs_datasets AS datasets
        ON url_map.gtfs_dataset_key = datasets.key
    LEFT JOIN fct_daily_schedule_feeds AS schedule
        ON datasets.schedule_to_use_for_rt_validation_gtfs_dataset_key = schedule.gtfs_dataset_key
        AND parse.dt = schedule.date
)

SELECT * FROM fct_daily_rt_feed_files
