WITH staging_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_guideway_age_distribution') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_track_and_roadway_guideway_age_distribution AS (
    SELECT
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
        stg.agency,
        stg.agency_voms,
        stg.city,
        stg.guideway_element,
        stg.mode,
        stg.mode_name,
        stg.ntd_id,
        stg.organization_type,
        stg.pre1940s,
        stg.pre1940s_q,
        stg.primary_uza_population,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_guideway_age_distribution AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_track_and_roadway_guideway_age_distribution
