WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
),

fct_ntd_annual_data__funding_sources_by_expense_type AS (
    SELECT *
    FROM staging_funding_sources_by_expense_type
)

SELECT * FROM fct_ntd_annual_data__funding_sources_by_expense_type
