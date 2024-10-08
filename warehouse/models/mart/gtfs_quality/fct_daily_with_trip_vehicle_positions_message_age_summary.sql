{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }
    )
}}

WITH vehicle_positions_ages AS (
    SELECT DISTINCT
        dt,
        gtfs_dataset_key,
        gtfs_dataset_name,
        trip_id IS NOT NULL AS with_trip,
        _header_message_age,
        _vehicle_message_age,
        _vehicle_message_age_vs_header
    FROM {{ ref('fct_vehicle_positions_messages') }}
    WHERE {{ incremental_where(default_start_var = 'PROD_GTFS_RT_START') }}
),

-- Deduplicating rows to the overall message level for meaningful summary statistics
vehicle_age_percentiles AS (
    SELECT
        *,
        -- Calculating percentiles for vehicle message age
        PERCENTILE_CONT(_vehicle_message_age, 0.5) OVER(PARTITION BY dt, gtfs_dataset_key, with_trip) AS median_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.25) OVER(PARTITION BY dt, gtfs_dataset_key, with_trip) AS p25_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.75) OVER(PARTITION BY dt, gtfs_dataset_key, with_trip) AS p75_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.90) OVER(PARTITION BY dt, gtfs_dataset_key, with_trip) AS p90_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.99) OVER(PARTITION BY dt, gtfs_dataset_key, with_trip) AS p99_vehicle_message_age
    FROM vehicle_positions_ages
),

summarize_vehicle_ages AS (
    SELECT
        dt,
        gtfs_dataset_key,
        gtfs_dataset_name,
        with_trip,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        MAX(_vehicle_message_age) AS max_vehicle_message_age,
        MIN(_vehicle_message_age) AS min_vehicle_message_age,
        AVG(_vehicle_message_age) AS avg_vehicle_message_age
    FROM vehicle_age_percentiles
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),

fct_daily_with_trip_vehicle_positions_message_age_summary AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'gtfs_dataset_key', 'with_trip']) }} AS key,
        dt,
        gtfs_dataset_key,
        gtfs_dataset_name,
        with_trip,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        max_vehicle_message_age,
        min_vehicle_message_age,
        avg_vehicle_message_age
    FROM summarize_vehicle_ages
    ORDER BY 1, 3, 4
)

SELECT *
FROM fct_daily_with_trip_vehicle_positions_message_age_summary
