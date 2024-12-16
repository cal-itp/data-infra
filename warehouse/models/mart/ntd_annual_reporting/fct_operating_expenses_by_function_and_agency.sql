WITH staging_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function_and_agency') }}
),

fct_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM staging_operating_expenses_by_function_and_agency
)

SELECT * FROM fct_operating_expenses_by_function_and_agency
