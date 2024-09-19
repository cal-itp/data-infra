WITH external_2022_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__funding_sources_by_expense_type') }}
),

stg_ntd_annual_data_tables__2022__funding_sources_by_expense_type AS (
    SELECT *
    FROM external_2022_funding_sources_by_expense_type
)

SELECT * FROM stg_ntd_annual_data_tables__2022__funding_sources_by_expense_type
