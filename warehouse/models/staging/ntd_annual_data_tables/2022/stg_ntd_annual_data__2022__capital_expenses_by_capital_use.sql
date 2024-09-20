WITH external_2022_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__capital_expenses_by_capital_use') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_2022_capital_expenses_by_capital_use
    -- we pull the whole world every day in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_annual_data_tables__2022__capital_expenses_by_capital_use AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_annual_data_tables__2022__capital_expenses_by_capital_use
