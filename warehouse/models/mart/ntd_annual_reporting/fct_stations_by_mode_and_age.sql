WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_by_mode_and_age') }}
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

fct_stations_by_mode_and_age AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.modes', 'stg.facility_type']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.modes,
        stg.mode_names,
        stg.facility_type,
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
        stg.organization_type,
        stg.pre1940,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_facilities,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_stations_by_mode_and_age AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_stations_by_mode_and_age
