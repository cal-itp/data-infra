WITH external_2022_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__service_by_mode_and_time_period') }}
),

stg_ntd_annual_data_tables__2022__service_by_mode_and_time_period AS (
    SELECT *
    FROM external_2022_service_by_mode_and_time_period
)

SELECT * FROM stg_ntd_annual_data_tables__2022__service_by_mode_and_time_period
