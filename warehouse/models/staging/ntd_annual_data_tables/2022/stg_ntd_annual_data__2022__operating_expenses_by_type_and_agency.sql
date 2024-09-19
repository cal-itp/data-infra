WITH external_2022_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__operating_expenses_by_type_and_agency') }}
),

stg_ntd_annual_data_tables__2022__operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM external_2022_operating_expenses_by_type_and_agency
)

SELECT * FROM stg_ntd_annual_data_tables__2022__operating_expenses_by_type_and_agency
