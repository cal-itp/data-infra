{{ config(materialized='table') }}

WITH latest_services AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__services'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_services AS (
    SELECT
        key,
        name,
        service_type,
        mode,
        currently_operating,
        operating_counties,
        gtfs_schedule_status,
        calitp_extracted_at
    FROM latest_services
)

SELECT * FROM dim_services
