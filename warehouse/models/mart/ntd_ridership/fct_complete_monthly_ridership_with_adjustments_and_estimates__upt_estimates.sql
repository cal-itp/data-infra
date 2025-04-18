WITH staging_upt_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates AS (
    SELECT
        stg.top_150,
        stg.ntd_id,
        stg.agency,
        stg.mode,
        stg.tos,
        stg.month,
        stg.year,
        stg.estimated_upt,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_upt_estimates AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__upt_estimates
