WITH external_2022_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__capital_expenses_by_mode') }}
),

stg_ntd_annual_data_tables__2022__capital_expenses_by_mode AS (
    SELECT *
    FROM external_2022_capital_expenses_by_mode
)

SELECT * FROM stg_ntd_annual_data_tables__2022__capital_expenses_by_mode
