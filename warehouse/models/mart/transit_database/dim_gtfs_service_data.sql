{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_service_data_dim') }}
),

dim_gtfs_service_data AS (
    SELECT
        key,
        name,
        service_key,
        gtfs_dataset_key,
        customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        fares_v2_status,
        _valid_from,
        _valid_to,
        _is_current
    FROM dim
)

SELECT * FROM dim_gtfs_service_data
