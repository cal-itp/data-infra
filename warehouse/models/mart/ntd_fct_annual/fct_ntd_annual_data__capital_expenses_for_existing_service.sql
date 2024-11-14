WITH staging_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__capital_expenses_for_existing_service') }}
),

fct_ntd_annual_data__capital_expenses_for_existing_service AS (
    SELECT *
    FROM staging_capital_expenses_for_existing_service
)

SELECT * FROM fct_ntd_annual_data__capital_expenses_for_existing_service
