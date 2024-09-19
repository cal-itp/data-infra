WITH external_2022_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__capital_expenses_for_expansion_of_service') }}
),

stg_ntd_annual_data_tables__2022__capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM external_2022_capital_expenses_for_expansion_of_service
)

SELECT * FROM stg_ntd_annual_data_tables__2022__capital_expenses_for_expansion_of_service
