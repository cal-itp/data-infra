WITH external_vehicles_age_distribution AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__vehicles_age_distribution') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_vehicles_age_distribution
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__vehicles_age_distribution AS (
    SELECT *
    FROM get_latest_extract
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
FROM stg_ntd__vehicles_age_distribution
