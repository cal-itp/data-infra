WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_vehicles_age_distribution AS (
    SELECT
        stg._0,
        stg._1,
        stg._10,
        stg._11,
        stg._12,
        stg._13_15,
        stg._16_20,
        stg._2,
        stg._21_25,
        stg._26_30,
        stg._3,
        stg._31_60,
        stg._4,
        stg._5,
        stg._6,
        stg._60,
        stg._7,
        stg._8,
        stg._9,
        stg.agency,
        stg.agency_voms,
        stg.average_age_of_fleet_in_years,
        stg.average_lifetime_miles_per,
        stg.city,
        stg.ntd_id,
        stg.organization_type,
        stg.primary_uza_population,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.total_vehicles,
        stg.uace_code,
        stg.uza_name,
        stg.vehicle_type,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_vehicles_age_distribution AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_vehicles_age_distribution
