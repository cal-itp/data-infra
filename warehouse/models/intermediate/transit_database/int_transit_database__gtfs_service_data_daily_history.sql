{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

date_spine AS (
    SELECT *
    FROM {{ ref('util_transit_database_history_date_spine') }}
),

int_transit_database__gtfs_service_data_daily_history AS (
    SELECT
        date_spine.date_day AS date,
        dim.key AS gtfs_service_data_key,
    FROM date_spine
    LEFT JOIN dim
        ON CAST(date_day AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
)

SELECT * FROM int_transit_database__gtfs_service_data_daily_history
