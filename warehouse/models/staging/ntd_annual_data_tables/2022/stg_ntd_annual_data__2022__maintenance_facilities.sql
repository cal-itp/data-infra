WITH external_2022_maintenance_facilities AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__maintenance_facilities') }}
),

stg_ntd_annual_data_tables__2022__maintenance_facilities AS (
    SELECT *
    FROM external_2022_maintenance_facilities
)

SELECT * FROM stg_ntd_annual_data_tables__2022__maintenance_facilities
