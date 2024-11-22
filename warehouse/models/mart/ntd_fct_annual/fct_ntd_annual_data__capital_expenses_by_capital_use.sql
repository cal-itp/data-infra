WITH staging_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__capital_expenses_by_capital_use') }}
),

fct_ntd_annual_data__capital_expenses_by_capital_use AS (
    SELECT *
    FROM staging_capital_expenses_by_capital_use
)

SELECT * FROM fct_ntd_annual_data__capital_expenses_by_capital_use
