{{ config(materialized='table') }}

WITH latest_funding_programs AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__funding_programs'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_funding_programs AS (
    SELECT
        key,
        program,
        category,
        calitp_extracted_at
    FROM latest_funding_programs
)

SELECT * FROM dim_funding_programs
