WITH external_2022_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__capital_expenses_by_capital_use') }}
),

stg_ntd_annual_data_tables__2022__capital_expenses_by_capital_use AS (
    SELECT *
    FROM external_2022_capital_expenses_by_capital_use
)

SELECT * FROM stg_ntd_annual_data_tables__2022__capital_expenses_by_capital_use
