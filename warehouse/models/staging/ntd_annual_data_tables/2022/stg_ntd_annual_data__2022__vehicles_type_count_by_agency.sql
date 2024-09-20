WITH external_2022_vehicles_type_count_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__vehicles_type_count_by_agency') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_vehicles_type_count_by_agency
    -- we pull the whole world every day in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data_tables__2022__vehicles_type_count_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data_tables__2022__vehicles_type_count_by_agency
