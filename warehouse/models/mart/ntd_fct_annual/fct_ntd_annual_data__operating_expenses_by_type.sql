WITH staging_operating_expenses_by_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_type') }}
),

fct_ntd_annual_data__operating_expenses_by_type AS (
    SELECT *
    FROM staging_operating_expenses_by_type
)

SELECT * FROM fct_ntd_annual_data__operating_expenses_by_type
