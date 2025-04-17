WITH staging_calendar_year_vrm AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm AS (
    SELECT *
    FROM staging_calendar_year_vrm
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm
