WITH staging_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_guideway_age_distribution') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_track_and_roadway_guideway_age_distribution AS (
    SELECT
        staging_track_and_roadway_guideway_age_distribution.*,
        dim_organizations.caltrans_district
    FROM staging_track_and_roadway_guideway_age_distribution
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_track_and_roadway_guideway_age_distribution.report_year = 2022 THEN
                staging_track_and_roadway_guideway_age_distribution.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_track_and_roadway_guideway_age_distribution.ntd_id = dim_organizations.ntd_id
        END
)

SELECT
    _1940s,
    _1940s_q,
    _1950s,
    _1950s_q,
    _1960s,
    _1960s_q,
    _1970s,
    _1970s_q,
    _1980s,
    _1980s_q,
    _1990s,
    _1990s_q,
    _2000s,
    _2000s_q,
    _2010s,
    _2010s_q,
    _2020s,
    _2020s_q,
    agency,
    agency_voms,
    city,
    guideway_element,
    mode,
    mode_name,
    ntd_id,
    organization_type,
    pre1940s,
    pre1940s_q,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    type_of_service,
    uace_code,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_track_and_roadway_guideway_age_distribution
