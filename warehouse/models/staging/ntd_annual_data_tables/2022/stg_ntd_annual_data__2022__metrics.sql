WITH external_2022_metrics AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__metrics') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_metrics
    -- we pull the whole world every day in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data_tables__2022__metrics AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data_tables__2022__metrics
