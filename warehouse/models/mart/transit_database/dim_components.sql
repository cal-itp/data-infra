{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__components'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_components AS (
    SELECT
        key,
        name,
        aliases,
        description,
        function_group,
        system,
        location,
        calitp_extracted_at
    FROM latest
)

SELECT * FROM dim_components
