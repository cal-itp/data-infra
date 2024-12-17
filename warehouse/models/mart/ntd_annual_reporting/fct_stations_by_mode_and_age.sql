WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_by_mode_and_age') }}
),

fct_stations_by_mode_and_age AS (
    SELECT *
    FROM staging_stations_by_mode_and_age
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
FROM fct_stations_by_mode_and_age
