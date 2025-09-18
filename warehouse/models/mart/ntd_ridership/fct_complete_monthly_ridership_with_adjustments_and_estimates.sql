{{ config(materialized="table") }}

WITH staging_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT
        stg.ntd_id,
        stg.agency,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.tos,
        stg.mode,
        stg.agency_mode_tos_date,
        stg.voms,
        stg.upt,
        stg._3_mode,
        stg.vrm,
        stg.uza_name,
        stg.uace_cd,
        stg.fta_region,
        stg.state,
        stg.reporter_type,
        stg.mode_type_of_service_status,
        stg.vrh,
        stg.legacy_ntd_id,
        stg.date,
        stg.dt,
        stg.execution_ts
    FROM staging_complete_monthly_ridership_with_adjustments_and_estimates AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates
