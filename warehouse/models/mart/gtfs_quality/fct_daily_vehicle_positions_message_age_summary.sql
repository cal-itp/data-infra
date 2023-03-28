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

WITH vehicle_positions_ages AS (
    SELECT DISTINCT
        dt,
        base64_url,
        _header_message_age,
        _vehicle_message_age,
        _vehicle_message_age_vs_header,
    FROM {{ ref('fct_vehicle_positions_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >=  {{ var('GTFS_RT_START') }}
    {% endif %}
),

-- these values are repeated because one row in the source table is one vehicle message so the header is identical for all messages on a given request
-- select distinct to deduplicate these to the overall message level to make summary statistics more meaningful
distinct_headers AS (
    SELECT DISTINCT
        dt,
        base64_url,
        _header_message_age,
    FROM vehicle_positions_ages
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

summarize_header_ages AS (
    SELECT
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
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

vehicle_age_percentiles AS (
    SELECT
        *,
        -- calculate median: https://stackoverflow.com/a/66213692
        PERCENTILE_CONT(_vehicle_message_age, .5) OVER(PARTITION BY dt, base64_url) AS median_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, .25) OVER(PARTITION BY dt, base64_url) AS p25_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, .75) OVER(PARTITION BY dt, base64_url) AS p75_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, .90) OVER(PARTITION BY dt, base64_url) AS p90_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, .99) OVER(PARTITION BY dt, base64_url) AS p99_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age_vs_header, .5) OVER(PARTITION BY dt, base64_url) AS median_vehicle_message_age_vs_header,
        PERCENTILE_CONT(_vehicle_message_age_vs_header, .25) OVER(PARTITION BY dt, base64_url) AS p25_vehicle_message_age_vs_header,
        PERCENTILE_CONT(_vehicle_message_age_vs_header, .75) OVER(PARTITION BY dt, base64_url) AS p75_vehicle_message_age_vs_header,
        PERCENTILE_CONT(_vehicle_message_age_vs_header, .90) OVER(PARTITION BY dt, base64_url) AS p90_vehicle_message_age_vs_header,
        PERCENTILE_CONT(_vehicle_message_age_vs_header, .99) OVER(PARTITION BY dt, base64_url) AS p99_vehicle_message_age_vs_header
    FROM vehicle_positions_ages
),

summarize_vehicle_ages AS (
    SELECT
        dt,
        base64_url,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        median_vehicle_message_age_vs_header,
        p25_vehicle_message_age_vs_header,
        p75_vehicle_message_age_vs_header,
        p90_vehicle_message_age_vs_header,
        p99_vehicle_message_age_vs_header,
        MAX(_vehicle_message_age) AS max_vehicle_message_age,
        MIN(_vehicle_message_age) AS min_vehicle_message_age,
        AVG(_vehicle_message_age) AS avg_vehicle_message_age,
        MAX(_vehicle_message_age_vs_header) AS max_vehicle_message_age_vs_header,
        MIN(_vehicle_message_age_vs_header) AS min_vehicle_message_age_vs_header,
        AVG(_vehicle_message_age_vs_header) AS avg_vehicle_message_age_vs_header,
    FROM vehicle_age_percentiles
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),

fct_daily_vehicle_positions_message_age_summary AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        base64_url,
        median_header_message_age,
        p25_header_message_age,
        p75_header_message_age,
        p90_header_message_age,
        p99_header_message_age,
        max_header_message_age,
        min_header_message_age,
        avg_header_message_age,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        max_vehicle_message_age,
        min_vehicle_message_age,
        avg_vehicle_message_age,
        median_vehicle_message_age_vs_header,
        p25_vehicle_message_age_vs_header,
        p75_vehicle_message_age_vs_header,
        p90_vehicle_message_age_vs_header,
        p99_vehicle_message_age_vs_header,
        max_vehicle_message_age_vs_header,
        min_vehicle_message_age_vs_header,
        avg_vehicle_message_age_vs_header
    FROM summarize_header_ages
    LEFT JOIN summarize_vehicle_ages
        USING (dt, base64_url)
)

SELECT * FROM fct_daily_vehicle_positions_message_age_summary
