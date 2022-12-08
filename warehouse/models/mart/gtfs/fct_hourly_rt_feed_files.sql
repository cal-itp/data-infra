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

parse_outcomes AS (
    SELECT *
    FROM int_gtfs_rt__unioned_parse_outcomes
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

hourly_tot AS (

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

pivoted_tots AS (

    SELECT

        daily_tot.dt,
        daily_tot.base64_url,
        daily_tot.feed_type,
        daily_tot.file_count_day,

        hourly_tot.* EXCEPT (dt, base64_url, feed_type)

    FROM daily_tot
    LEFT JOIN hourly_tot
        ON daily_tot.dt = hourly_tot.dt
            AND daily_tot.base64_url = hourly_tot.base64_url
            AND daily_tot.feed_type = hourly_tot.feed_type

),

fct_hourly_rt_feed_files AS (
    SELECT

        {{ dbt_utils.surrogate_key(['pivoted_tots.dt', 'pivoted_tots.base64_url']) }} AS key,

        url_index.dt,
        url_index.string_url,
        url_index.base64_url,
        url_index.type AS feed_type,

        pivoted_tots.* EXCEPT (dt, base64_url, feed_type)

    FROM int_gtfs_rt__daily_url_index AS url_index
    LEFT JOIN pivoted_tots
        ON url_index.dt = pivoted_tots.dt
            AND url_index.base64_url = pivoted_tots.base64_url
            AND url_index.type = pivoted_tots.feed_type

)

SELECT * FROM fct_hourly_rt_feed_files
