{{ config(materialized='table') }}

WITH dim_gtfs_service_data AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

joined AS (
    SELECT
        service_key,
        gtfs_dataset_key,
        category,
        CASE
            WHEN data = 'GTFS Schedule' THEN 'schedule'
            WHEN data = 'GTFS Alerts' THEN 'service_alerts'
            WHEN data = 'GTFS TripUpdates' THEN 'trip_updates'
            WHEN data = 'GTFS VehiclePositions' THEN 'vehicle_positions'
        END AS type
    FROM dim_gtfs_service_data
    LEFT JOIN dim_gtfs_datasets
        ON dim_gtfs_service_data.gtfs_dataset_key = dim_gtfs_datasets.key
),

quartet_pivoted AS (
    SELECT *
    FROM joined
    PIVOT(
        ARRAY_AGG(gtfs_dataset_key IGNORE NULLS) AS gtfs_dataset_key
        FOR type IN ('schedule', 'service_alerts', 'trip_updates', 'vehicle_positions')
    )
)

SELECT * FROM quartet_pivoted
