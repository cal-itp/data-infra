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

daily_tots AS (

    SELECT

        dt,
        base64_url,
        feed_type,
        COALESCE(COUNT(*), 0) AS file_count_day,
        SUM(
            CASE parse_success WHEN TRUE THEN 1 ELSE 0 END
        ) AS success_file_count_day,
        (
            SUM(CASE parse_success WHEN TRUE THEN 1 ELSE 0 END) / COUNT(*)
        ) * 100 AS pct_success_file_count_day

    FROM parse_outcomes
    GROUP BY
        dt,
        base64_url,
        feed_type

),

hourly_tots AS (

    SELECT

        dt,
        base64_url,
        feed_type,
        EXTRACT(
            HOUR FROM hour AT TIME ZONE "America/Los_Angeles"
        ) AS download_hour,
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

pivot_hourly_tots AS (

    SELECT *
    FROM
        (SELECT

            dt,
            download_hour,
            base64_url,
            feed_type,
            (
                COALESCE(
                    (success_file_count_hour), 0
                ) / COALESCE(file_count_hour, 0)
            ) * 100 AS pct_success_hour

            FROM hourly_tots)
    PIVOT(
        SUM(pct_success_hour)
        FOR download_hour IN
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
            11, 12, 13, 14, 15, 16, 17, 18, 19,
            20, 21, 22, 23)
    )
),

joined_tots AS (

    SELECT

        pivot_hourly_tots.* EXCEPT (dt, base64_url, feed_type),
        daily_tots.dt,
        daily_tots.base64_url,
        daily_tots.feed_type,

        --these are probably extraneous and can be removed
        daily_tots.pct_success_file_count_day,
        daily_tots.file_count_day,

        daily_tots.success_file_count_day

    FROM daily_tots
    LEFT JOIN pivot_hourly_tots
        ON daily_tots.dt = pivot_hourly_tots.dt
            AND daily_tots.base64_url = pivot_hourly_tots.base64_url
            AND daily_tots.feed_type = pivot_hourly_tots.feed_type

),

fct_hourly_rt_feed_files_success AS (
    SELECT

        joined_tots.* EXCEPT (dt, base64_url, feed_type),

        url_index.dt,
        url_index.string_url,
        url_index.base64_url,
        url_index.type AS feed_type,

        TO_HEX(
            MD5(
                CAST(
                    COALESCE(
                        CAST(joined_tots.dt AS STRING), ""
                    ) || "-" || COALESCE(
                        CAST(joined_tots.base64_url AS STRING), ""
                    ) AS STRING
                )
            )
        ) AS key

    FROM int_gtfs_rt__daily_url_index AS url_index
    LEFT JOIN joined_tots
        ON url_index.dt = joined_tots.dt
            AND url_index.base64_url = joined_tots.base64_url
            AND url_index.type = joined_tots.feed_type

)

SELECT * FROM fct_hourly_rt_feed_files_success
