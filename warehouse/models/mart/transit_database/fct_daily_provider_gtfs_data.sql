{{ config(materialized='table') }}

WITH dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

date_spine AS (
    SELECT date_day AS date
    FROM {{ ref('util_transit_database_history_date_spine') }}
),

fct_daily_provider_gtfs_data AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('dim_provider_gtfs_data') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
)

SELECT * FROM fct_daily_provider_gtfs_data
