WITH staging_upt AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__upt AS (
    SELECT *
    FROM staging_upt
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__upt
