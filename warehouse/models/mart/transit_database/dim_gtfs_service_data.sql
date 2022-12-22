{{ config(materialized='table') }}

WITH latest_gtfs_service_data AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__gtfs_service_data'),
        order_by = 'dt DESC'
        ) }}
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
        dt
    FROM latest_gtfs_service_data
)

SELECT * FROM dim_gtfs_service_data
