WITH staging_track_and_roadway_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_mode') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_track_and_roadway_by_mode AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.at_grade_ballast_including,
        stg.at_grade_ballast_including_1,
        stg.at_grade_in_street_embedded,
        stg.at_grade_in_street_embedded_1,
        stg.below_grade_bored_or_blasted,
        stg.below_grade_bored_or_blasted_1,
        stg.below_grade_cut_and_cover,
        stg.below_grade_cut_and_cover_1,
        stg.below_grade_retained_cut,
        stg.below_grade_retained_cut_1,
        stg.below_grade_submerged_tube,
        stg.below_grade_submerged_tube_1,
        stg.city,
        stg.controlled_access_high,
        stg.controlled_access_high_1,
        stg.double_crossover,
        stg.double_crossover_q,
        stg.elevated_concrete,
        stg.elevated_concrete_q,
        stg.elevated_retained_fill,
        stg.elevated_retained_fill_q,
        stg.elevated_steel_viaduct_or,
        stg.elevated_steel_viaduct_or_1,
        stg.exclusive_fixed_guideway,
        stg.exclusive_fixed_guideway_1,
        stg.exclusive_high_intensity,
        stg.exclusive_high_intensity_1,
        stg.grade_crossings,
        stg.grade_crossings_q,
        stg.lapped_turnout,
        stg.lapped_turnout_q,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.ntd_id,
        stg.organization_type,
        stg.primary_uza_population,
        stg.rail_crossings,
        stg.rail_crossings_q,
        stg.report_year,
        stg.reporter_type,
        stg.single_crossover,
        stg.single_crossover_q,
        stg.single_turnout,
        stg.single_turnout_q,
        stg.slip_switch,
        stg.slip_switch_q,
        stg.state,
        stg.total_miles,
        stg.total_track_miles,
        stg.total_track_miles_q,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_by_mode AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    WHERE stg.state = 'CA'
)

SELECT * FROM fct_track_and_roadway_by_mode
