WITH external_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__stations_by_mode_and_age') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_stations_by_mode_and_age
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data__stations_by_mode_and_age AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data__stations_by_mode_and_age
