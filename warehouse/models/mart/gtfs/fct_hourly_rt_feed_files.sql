{{ config(materialized='incremental', unique_key = 'key') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max date in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
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
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)
    {% endif %}
),

daily_tot AS (

    SELECT
        dt,
        base64_url,
        feed_type,
        COUNT(*) as file_count_day
    FROM parse_outcomes
    GROUP BY
        dt,
        base64_url,
        feed_type

),

wide_hourly AS (

    SELECT *
    FROM
        (SELECT
        dt,
        EXTRACT(HOUR FROM hour AT TIME ZONE "America/Los_Angeles") as download_hour,
        base64_url,
        feed_type,
        FROM parse_outcomes)
    PIVOT(
        COUNT(*) file_count_hr
        FOR download_hour IN
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15, 16, 17, 18, 19,
            20, 21, 22, 23)
    )
),

pivoted_parse_outcomes AS (

    SELECT *
    FROM daily_tot
    LEFT JOIN wide_hourly
        USING (dt, base64_url, feed_type)

),

fct_hourly_rt_feed_files AS (
    SELECT
        parse.*,
        {{ dbt_utils.surrogate_key(['parse.dt', 'parse.base64_url']) }} AS key,
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

SELECT * FROM fct_hourly_rt_feed_files
