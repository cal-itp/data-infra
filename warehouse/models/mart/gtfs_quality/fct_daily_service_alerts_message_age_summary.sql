{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH service_alerts_ages AS (
    SELECT DISTINCT
        dt,
        base64_url,
        _header_message_age,
    FROM {{ ref('fct_service_alerts_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >=  {{ var('GTFS_RT_START') }}
    {% endif %}
),

-- these values are repeated because one row in the source table is one service_alerts message so the header is identical for all messages on a given request
-- select distinct to deduplicate these to the overall message level to make summary statistics more meaningful
distinct_headers AS (
    SELECT DISTINCT
        dt,
        base64_url,
        _header_message_age,
    FROM service_alerts_ages
),

header_age_percentiles AS (
    SELECT
        *,
        -- calculate median: https://stackoverflow.com/a/66213692
        PERCENTILE_CONT(_header_message_age, .5) OVER(PARTITION BY dt, base64_url) AS median_header_message_age,
        PERCENTILE_CONT(_header_message_age, .25) OVER(PARTITION BY dt, base64_url) AS p25_header_message_age,
        PERCENTILE_CONT(_header_message_age, .75) OVER(PARTITION BY dt, base64_url) AS p75_header_message_age,
        PERCENTILE_CONT(_header_message_age, .90) OVER(PARTITION BY dt, base64_url) AS p90_header_message_age,
        PERCENTILE_CONT(_header_message_age, .99) OVER(PARTITION BY dt, base64_url) AS p99_header_message_age
    FROM distinct_headers
),

fct_daily_service_alerts_message_age_summary AS (
    SELECT
        {{ dbt_utils.surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        base64_url,
        median_header_message_age,
        p25_header_message_age,
        p75_header_message_age,
        p90_header_message_age,
        p99_header_message_age,
        MAX(_header_message_age) AS max_header_message_age,
        MIN(_header_message_age) AS min_header_message_age,
        AVG(_header_message_age) AS avg_header_message_age,
    FROM header_age_percentiles
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_daily_service_alerts_message_age_summary
