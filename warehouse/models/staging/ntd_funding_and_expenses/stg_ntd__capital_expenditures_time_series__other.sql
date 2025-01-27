WITH
    source AS (
        SELECT *
          FROM {{ source('external_ntd__funding_and_expenses', 'historical__capital_expenditures_time_series__other') }}
    ),

    stg_ntd__capital_expenditures_time_series__other AS(
        SELECT *
          FROM source
        -- we pull the whole table every month in the pipeline, so this gets only the latest extract
        QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
    )

SELECT * FROM stg_ntd__capital_expenditures_time_series__other
