WITH staging_operating_expenses_by_function AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function') }}
),

fct_ntd_annual_data__operating_expenses_by_function AS (
    SELECT *
    FROM staging_operating_expenses_by_function
)

SELECT * FROM fct_ntd_annual_data__operating_expenses_by_function
