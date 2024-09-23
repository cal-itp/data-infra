WITH external_2022_vehicles_age_distribution AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__vehicles_age_distribution') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_vehicles_age_distribution
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data_tables__2022__vehicles_age_distribution AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data_tables__2022__vehicles_age_distribution
