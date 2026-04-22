{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time = 'dt',
        batch_size = 'day',
        begin=var('GTFS_RT_START'),
        lookback=var('DBT_ALL_MICROBATCH_LOOKBACK_DAYS'),
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        full_refresh=false,
        on_schema_change='sync_all_columns'
    )
}}

WITH trip_updates_ages AS (
    SELECT
        dt,
        base64_url,
        _extract_ts,
        gtfs_dataset_key,
        gtfs_dataset_name,
        _header_message_age,
        _trip_update_message_age
    FROM {{ ref('fct_trip_updates_no_stop_times') }}
    WHERE {{ incremental_where(default_start_var='GTFS_RT_START') }}
),

-- these values are repeated because one row in the source table is one trip_updates message so the header is identical for all messages on a given request
-- select distinct to deduplicate these to the overall message level to make summary statistics more meaningful
distinct_headers AS (
    SELECT DISTINCT
        dt,
        base64_url,
        _extract_ts,
        _header_message_age,
    FROM trip_updates_ages
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

trip_updates_age_percentiles AS (
    SELECT
        *,
        -- calculate median: https://stackoverflow.com/a/66213692
        PERCENTILE_CONT(_trip_update_message_age, .5) OVER(PARTITION BY dt, base64_url) AS median_trip_update_message_age,
        PERCENTILE_CONT(_trip_update_message_age, .25) OVER(PARTITION BY dt, base64_url) AS p25_trip_update_message_age,
        PERCENTILE_CONT(_trip_update_message_age, .75) OVER(PARTITION BY dt, base64_url) AS p75_trip_update_message_age,
        PERCENTILE_CONT(_trip_update_message_age, .90) OVER(PARTITION BY dt, base64_url) AS p90_trip_update_message_age,
        PERCENTILE_CONT(_trip_update_message_age, .99) OVER(PARTITION BY dt, base64_url) AS p99_trip_update_message_age,
    FROM trip_updates_ages
),

summarize_trip_updates_ages AS (
    SELECT
        dt,
        base64_url,
        gtfs_dataset_key,
        gtfs_dataset_name,
        median_trip_update_message_age,
        p25_trip_update_message_age,
        p75_trip_update_message_age,
        p90_trip_update_message_age,
        p99_trip_update_message_age,
        MAX(_trip_update_message_age) AS max_trip_update_message_age,
        MIN(_trip_update_message_age) AS min_trip_update_message_age,
        AVG(_trip_update_message_age) AS avg_trip_update_message_age,
    FROM trip_updates_age_percentiles
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),

fct_daily_trip_update_message_age_summary AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        base64_url,
        gtfs_dataset_key,
        gtfs_dataset_name,
        median_header_message_age,
        p25_header_message_age,
        p75_header_message_age,
        p90_header_message_age,
        p99_header_message_age,
        max_header_message_age,
        min_header_message_age,
        avg_header_message_age,
        median_trip_update_message_age,
        p25_trip_update_message_age,
        p75_trip_update_message_age,
        p90_trip_update_message_age,
        p99_trip_update_message_age,
        max_trip_update_message_age,
        min_trip_update_message_age,
        avg_trip_update_message_age,
    FROM summarize_header_ages
    LEFT JOIN summarize_trip_updates_ages
        USING (dt, base64_url)
)

SELECT * FROM fct_daily_trip_update_message_age_summary
