WITH staging_vrm_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates AS (
    SELECT *
    FROM staging_vrm_estimates
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates
