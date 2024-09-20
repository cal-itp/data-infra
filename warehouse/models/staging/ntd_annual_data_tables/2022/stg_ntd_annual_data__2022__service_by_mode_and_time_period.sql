WITH external_2022_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__service_by_mode_and_time_period') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_service_by_mode_and_time_period
    -- we pull the whole world every day in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data_tables__2022__service_by_mode_and_time_period AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data_tables__2022__service_by_mode_and_time_period
