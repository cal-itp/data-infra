WITH staging_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_mode') }}
),

fct_capital_expenses_by_mode AS (
    SELECT *
    FROM staging_capital_expenses_by_mode
)

SELECT * FROM fct_capital_expenses_by_mode
