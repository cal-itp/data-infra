WITH staging_vrh AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__vrh') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__vrh AS (
    SELECT *
    FROM staging_vrh
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__vrh
