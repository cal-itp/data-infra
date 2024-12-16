WITH staging_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_for_expansion_of_service') }}
),

fct_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM staging_capital_expenses_for_expansion_of_service
)

SELECT * FROM fct_capital_expenses_for_expansion_of_service
