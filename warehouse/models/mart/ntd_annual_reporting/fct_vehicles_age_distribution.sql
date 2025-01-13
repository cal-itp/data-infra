WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

fct_vehicles_age_distribution AS (
    SELECT *
    FROM staging_vehicles_age_distribution
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
    dt,
    execution_ts
FROM fct_vehicles_age_distribution
