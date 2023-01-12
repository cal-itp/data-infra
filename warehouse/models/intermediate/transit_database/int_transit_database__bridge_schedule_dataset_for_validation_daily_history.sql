{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('bridge_schedule_dataset_for_validation') }}
),

date_spine AS (
    SELECT *
    FROM {{ ref('util_transit_database_history_date_spine') }}
),

int_transit_database__bridge_schedule_dataset_for_validation_daily_history AS (
    SELECT
        date_spine.date_day AS date,
        dim.gtfs_dataset_key,
        dim.schedule_to_use_for_rt_validation_gtfs_dataset_key
    FROM date_spine
    LEFT JOIN dim
        ON CAST(date_day AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
)

SELECT * FROM int_transit_database__bridge_schedule_dataset_for_validation_daily_history
