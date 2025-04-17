WITH staging_vrm AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__vrm') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__vrm AS (
    SELECT *
    FROM staging_vrm
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__vrm
