WITH staging_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_guideway_age_distribution') }}
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

fct_track_and_roadway_guideway_age_distribution AS (
    SELECT
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg._1940s,
        stg._1940s_q,
        stg._1950s,
        stg._1950s_q,
        stg._1960s,
        stg._1960s_q,
        stg._1970s,
        stg._1970s_q,
        stg._1980s,
        stg._1980s_q,
        stg._1990s,
        stg._1990s_q,
        stg._2000s,
        stg._2000s_q,
        stg._2010s,
        stg._2010s_q,
        stg._2020s,
        stg._2020s_q,
        stg.agency_voms,
        stg.guideway_element,
        stg.mode,
        stg.mode_name,
        stg.organization_type,
        stg.pre1940s,
        stg.pre1940s_q,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_guideway_age_distribution AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_track_and_roadway_guideway_age_distribution
