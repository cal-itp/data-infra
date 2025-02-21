WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_vehicles_age_distribution.*,
        current_dim_organizations.caltrans_district
    FROM staging_vehicles_age_distribution
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_vehicles_age_distribution AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    _0,
    _1,
    _10,
    _11,
    _12,
    _13_15,
    _16_20,
    _2,
    _21_25,
    _26_30,
    _3,
    _31_60,
    _4,
    _5,
    _6,
    _60,
    _7,
    _8,
    _9,
    agency,
    agency_voms,
    average_age_of_fleet_in_years,
    average_lifetime_miles_per,
    city,
    ntd_id,
    organization_type,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_vehicles,
    uace_code,
    uza_name,
    vehicle_type,
    caltrans_district,
    dt,
    execution_ts
FROM fct_vehicles_age_distribution
