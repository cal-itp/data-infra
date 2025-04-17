WITH staging_calendar_year_vrm AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm AS (
    SELECT
        stg.*,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current
    FROM staging_calendar_year_vrm AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm
