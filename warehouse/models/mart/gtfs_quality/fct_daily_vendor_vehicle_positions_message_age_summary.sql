{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH vehicle_positions_ages AS (
    SELECT DISTINCT
        dt,
        gtfs_dataset_key,
        _header_message_age,
        _vehicle_message_age,
        _vehicle_message_age_vs_header
    FROM {{ ref('fct_vehicle_positions_messages') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

-- these values are repeated because one row in the source table is one vehicle message so the header is identical for all messages on a given request
-- select distinct to deduplicate these to the overall message level to make summary statistics more meaningful

vendor_vehicle_positions_ages AS (
    SELECT DISTINCT
        dt,
        organization_name,
        _header_message_age,
        _vehicle_message_age,
        _vehicle_message_age_vs_header
    FROM vehicle_positions_ages AS VPA
    INNER JOIN {{ ref('bridge_organizations_x_gtfs_datasets_produced') }} AS BOGD
        ON VPA.gtfs_dataset_key = BOGD.gtfs_dataset_key
        AND dt BETWEEN DATE(_valid_from) AND DATE(_valid_to)
),


vehicle_age_percentiles AS (
    SELECT
        *,
        PERCENTILE_CONT(_vehicle_message_age, 0.5) OVER(PARTITION BY dt, organization_name) AS median_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.25) OVER(PARTITION BY dt, organization_name) AS p25_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.75) OVER(PARTITION BY dt, organization_name) AS p75_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.90) OVER(PARTITION BY dt, organization_name) AS p90_vehicle_message_age,
        PERCENTILE_CONT(_vehicle_message_age, 0.99) OVER(PARTITION BY dt, organization_name) AS p99_vehicle_message_age
    FROM vendor_vehicle_positions_ages
),

summarize_vehicle_ages AS (
    SELECT
        dt,
        organization_name,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        MAX(_vehicle_message_age) AS max_vehicle_message_age,
        MIN(_vehicle_message_age) AS min_vehicle_message_age,
        AVG(_vehicle_message_age) AS avg_vehicle_message_age
    FROM vehicle_age_percentiles
    GROUP BY
        dt, organization_name,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age
),

fct_daily_vendor_vehicle_positions_message_age_summary AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'organization_name']) }} AS key,
        dt,
        organization_name,
        median_vehicle_message_age,
        p25_vehicle_message_age,
        p75_vehicle_message_age,
        p90_vehicle_message_age,
        p99_vehicle_message_age,
        max_vehicle_message_age,
        min_vehicle_message_age,
        avg_vehicle_message_age
    FROM summarize_vehicle_ages
)

SELECT *
FROM fct_daily_vendor_vehicle_positions_message_age_summary
