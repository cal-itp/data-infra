WITH staging_upt_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates AS (
    SELECT *
    FROM staging_upt_estimates
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates
