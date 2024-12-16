WITH external_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_for_existing_service') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_capital_expenses_for_existing_service
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_for_existing_service AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__capital_expenses_for_existing_service
