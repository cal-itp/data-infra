WITH staging_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__capital_expenses_for_expansion_of_service') }}
),

fct_ntd_annual_data__capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM staging_capital_expenses_for_expansion_of_service
)

SELECT * FROM fct_ntd_annual_data__capital_expenses_for_expansion_of_service
