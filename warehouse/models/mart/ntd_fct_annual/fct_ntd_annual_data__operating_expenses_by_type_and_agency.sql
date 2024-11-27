WITH staging_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__operating_expenses_by_type_and_agency') }}
),

fct_ntd_annual_data__operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM staging_operating_expenses_by_type_and_agency
)

SELECT * FROM fct_ntd_annual_data__operating_expenses_by_type_and_agency
