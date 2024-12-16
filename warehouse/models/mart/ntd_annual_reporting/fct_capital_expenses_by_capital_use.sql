WITH staging_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_capital_use') }}
),

fct_capital_expenses_by_capital_use AS (
    SELECT *
    FROM staging_capital_expenses_by_capital_use
)

SELECT * FROM fct_capital_expenses_by_capital_use
