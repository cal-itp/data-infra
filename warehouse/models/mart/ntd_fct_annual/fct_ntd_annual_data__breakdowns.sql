WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__breakdowns') }}
),

fct_ntd_annual_data__breakdowns AS (
    SELECT *
    FROM staging_breakdowns
)

SELECT * FROM fct_ntd_annual_data__breakdowns
