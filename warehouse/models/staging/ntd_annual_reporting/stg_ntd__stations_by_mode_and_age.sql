WITH external_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__stations_by_mode_and_age') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_stations_by_mode_and_age
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__stations_by_mode_and_age AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    _1940s,
    _1950s,
    _1960s,
    _1970s,
    _1980s,
    _1990s,
    _2000s,
    _2010s,
    _2020s,
    agency,
    agency_voms,
    city,
    facility_type,
    mode_names,
    modes,
    ntd_id,
    organization_type,
    pre1940,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_facilities,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__stations_by_mode_and_age
