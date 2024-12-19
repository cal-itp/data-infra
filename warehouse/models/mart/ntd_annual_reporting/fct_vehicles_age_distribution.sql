WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_vehicles_age_distribution AS (
    SELECT
        staging_vehicles_age_distribution.*,
        dim_organizations.caltrans_district
    FROM staging_vehicles_age_distribution
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_vehicles_age_distribution.report_year = 2022 THEN
                staging_vehicles_age_distribution.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_vehicles_age_distribution.ntd_id = dim_organizations.ntd_id
        END
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
