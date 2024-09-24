WITH external_historical_complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates AS (
    SELECT *
    FROM {{ source('external_ntd__ridership', 'historical__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_historical_complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_ridership_historical__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_ridership_historical__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates
