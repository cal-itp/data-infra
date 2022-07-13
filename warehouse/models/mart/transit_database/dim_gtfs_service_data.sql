{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__gtfs_service_data'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
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
    FROM latest
)

SELECT * FROM dim_gtfs_service_data
