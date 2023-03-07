{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_service_data_dim') }}
),

dim_gtfs_service_data AS (
    SELECT
        key,
        name,
        source_record_id,
        service_key,
        gtfs_dataset_key,
        customer_facing,
        category,
        fares_v2_status,
        manual_check__fixed_route_completeness,
        manual_check__demand_response_completeness,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_gtfs_service_data
