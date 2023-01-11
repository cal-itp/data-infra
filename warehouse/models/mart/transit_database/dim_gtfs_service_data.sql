{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_service_data_dim') }}
),

dim_gtfs_service_data AS (
    SELECT
        dim.key,
        dim.name,
        dim.original_record_id,
        service_key,
        gtfs_dataset_key,
        dim.customer_facing,
        dim.category,
        dim.agency_id,
        dim.network_id,
        dim.route_id,
        dim.fares_v2_status,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_gtfs_service_data
