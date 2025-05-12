WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_by_mode_and_age') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_stations_by_mode_and_age AS (
    SELECT
        stg.agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
        stg._1940s,
        stg._1950s,
        stg._1960s,
        stg._1970s,
        stg._1980s,
        stg._1990s,
        stg._2000s,
        stg._2010s,
        stg._2020s,
        stg.agency_voms,
        stg.facility_type,
        stg.mode_names,
        stg.modes,
        stg.organization_type,
        stg.pre1940,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_facilities,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_stations_by_mode_and_age AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_stations_by_mode_and_age
