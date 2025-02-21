WITH staging_track_and_roadway_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_mode') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_track_and_roadway_by_mode.*,
        current_dim_organizations.caltrans_district
    FROM staging_track_and_roadway_by_mode
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_track_and_roadway_by_mode AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    agency_voms,
    at_grade_ballast_including,
    at_grade_ballast_including_1,
    at_grade_in_street_embedded,
    at_grade_in_street_embedded_1,
    below_grade_bored_or_blasted,
    below_grade_bored_or_blasted_1,
    below_grade_cut_and_cover,
    below_grade_cut_and_cover_1,
    below_grade_retained_cut,
    below_grade_retained_cut_1,
    below_grade_submerged_tube,
    below_grade_submerged_tube_1,
    city,
    controlled_access_high,
    controlled_access_high_1,
    double_crossover,
    double_crossover_q,
    elevated_concrete,
    elevated_concrete_q,
    elevated_retained_fill,
    elevated_retained_fill_q,
    elevated_steel_viaduct_or,
    elevated_steel_viaduct_or_1,
    exclusive_fixed_guideway,
    exclusive_fixed_guideway_1,
    exclusive_high_intensity,
    exclusive_high_intensity_1,
    grade_crossings,
    grade_crossings_q,
    lapped_turnout,
    lapped_turnout_q,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    primary_uza_population,
    rail_crossings,
    rail_crossings_q,
    report_year,
    reporter_type,
    single_crossover,
    single_crossover_q,
    single_turnout,
    single_turnout_q,
    slip_switch,
    slip_switch_q,
    state,
    total_miles,
    total_track_miles,
    total_track_miles_q,
    type_of_service,
    uace_code,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_track_and_roadway_by_mode
