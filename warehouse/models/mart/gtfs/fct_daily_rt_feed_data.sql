{{ config(materialized='incremental') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max date in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_date = dates[0] %}
{% endif %}

WITH parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= DATE '{{ max_date }}'
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)
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

fct_daily_rt_feed_data AS (
    SELECT
        {{ dbt_utils.surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        base64_url,
        feed_type,
        parse_success_file_count,
        parse_failure_file_count
    FROM grouped_parse_outcomes
    PIVOT(SUM(file_count) FOR aggregation_outcome IN ("parse_success_file_count", "parse_failure_file_count"))
)

SELECT * FROM fct_daily_rt_feed_data
