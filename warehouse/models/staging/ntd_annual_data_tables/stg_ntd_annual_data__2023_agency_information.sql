WITH external_agency_information AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2023__annual_database_agency_information') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_agency_information
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data__2023_agency_information AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data__2023_agency_information
