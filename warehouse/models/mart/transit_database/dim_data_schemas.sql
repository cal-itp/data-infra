{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__data_schemas'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_data_schemas AS (
    SELECT
        key,
        name,
        status,
        calitp_extracted_at
    FROM latest
)

SELECT * FROM dim_data_schemas
