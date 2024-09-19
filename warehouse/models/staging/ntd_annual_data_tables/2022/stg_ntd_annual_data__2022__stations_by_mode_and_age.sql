WITH external_2022_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__stations_by_mode_and_age') }}
),

stg_ntd_annual_data_tables__2022__stations_by_mode_and_age AS (
    SELECT *
    FROM external_2022_stations_by_mode_and_age
)

SELECT * FROM stg_ntd_annual_data_tables__2022__stations_by_mode_and_age
