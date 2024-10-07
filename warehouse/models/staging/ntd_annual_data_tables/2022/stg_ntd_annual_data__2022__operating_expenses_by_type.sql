WITH external_2022_operating_expenses_by_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__operating_expenses_by_type') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_operating_expenses_by_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data__2022__operating_expenses_by_type AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data__2022__operating_expenses_by_type