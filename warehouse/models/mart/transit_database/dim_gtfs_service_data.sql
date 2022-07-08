{{ config(materialized='table') }}

WITH stg_transit_database__gtfs_service_data AS (
    SELECT * FROM {{ ref('stg_transit_database__gtfs_service_data') }}
),

dim_gtfs_service_data AS (
    SELECT
        key,
        name,
        service_key,
        gtfs_dataset_key,
        category,
        agency_id,
        network_id,
        route_id,
        reference_static_gtfs_service_data_key,
        calitp_extracted_at
    FROM stg_transit_database__gtfs_service_data
)

SELECT * FROM dim_gtfs_service_data
