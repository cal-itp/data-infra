WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_by_mode_and_age') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_stations_by_mode_and_age AS (
    SELECT
        staging_stations_by_mode_and_age.*,
        dim_organizations.caltrans_district
    FROM staging_stations_by_mode_and_age
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_stations_by_mode_and_age.report_year = 2022 THEN
                staging_stations_by_mode_and_age.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_stations_by_mode_and_age.ntd_id = dim_organizations.ntd_id
        END
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_stations_by_mode_and_age
