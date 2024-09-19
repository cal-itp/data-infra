WITH external_2022_fuel_and_energy AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__fuel_and_energy') }}
),

stg_ntd_annual_data_tables__2022__fuel_and_energy AS (
    SELECT *
    FROM external_2022_fuel_and_energy
)

SELECT * FROM stg_ntd_annual_data_tables__2022__fuel_and_energy
