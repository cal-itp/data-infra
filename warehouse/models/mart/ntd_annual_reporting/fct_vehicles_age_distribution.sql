WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_vehicles_age_distribution AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.vehicle_type,
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
        stg.agency_voms,
        stg.average_age_of_fleet_in_years,
        stg.average_lifetime_miles_per,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_vehicles,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_vehicles_age_distribution AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_vehicles_age_distribution
