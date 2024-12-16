WITH staging_voms AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__voms') }}
),

stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__voms AS (
    SELECT *
    FROM staging_voms
)

SELECT * FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__voms
