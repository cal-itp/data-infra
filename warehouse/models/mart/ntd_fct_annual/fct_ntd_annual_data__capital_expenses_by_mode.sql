WITH staging_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_mode') }}
),

fct_ntd_annual_data__capital_expenses_by_mode AS (
    SELECT *
    FROM staging_capital_expenses_by_mode
)

SELECT * FROM fct_ntd_annual_data__capital_expenses_by_mode
