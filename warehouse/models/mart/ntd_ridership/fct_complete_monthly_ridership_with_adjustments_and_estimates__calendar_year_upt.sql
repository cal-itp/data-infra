WITH staging_calendar_year_upt AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_upt') }}
),

stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_upt AS (
    SELECT *
    FROM staging_calendar_year_upt
)

SELECT * FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_upt
