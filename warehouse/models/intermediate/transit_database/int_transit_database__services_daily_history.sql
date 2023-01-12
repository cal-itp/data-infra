{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('dim_services') }}
),

date_spine AS (
    SELECT *
    FROM {{ ref('util_transit_database_history_date_spine') }}
),

int_gtfs_quality__services_daily_history AS (
    SELECT
        date_spine.date_day,
        dim.key AS service_key,
    FROM date_spine
    LEFT JOIN dim
        ON CAST(date_day AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
)

SELECT * FROM int_gtfs_quality__services_daily_history
