WITH staging_master AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__master') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__master AS (
    SELECT *
    FROM staging_master
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__master
