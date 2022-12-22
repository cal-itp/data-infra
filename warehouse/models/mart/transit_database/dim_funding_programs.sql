{{ config(materialized='table') }}

WITH latest_funding_programs AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__funding_programs'),
        order_by = 'dt DESC'
        ) }}
),

dim_funding_programs AS (
    SELECT
        key,
        program,
        category,
        dt
    FROM latest_funding_programs
)

SELECT * FROM dim_funding_programs
