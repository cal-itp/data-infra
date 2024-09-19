WITH external_2022_vehicles_type_count_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__vehicles_type_count_by_agency') }}
),

stg_ntd_annual_data_tables__2022__vehicles_type_count_by_agency AS (
    SELECT *
    FROM external_2022_vehicles_type_count_by_agency
)

SELECT * FROM stg_ntd_annual_data_tables__2022__vehicles_type_count_by_agency
