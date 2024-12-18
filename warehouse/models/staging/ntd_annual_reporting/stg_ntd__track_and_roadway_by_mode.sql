WITH external_track_and_roadway_by_mode AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__track_and_roadway_by_mode') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_track_and_roadway_by_mode
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__track_and_roadway_by_mode AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    SAFE_CAST(at_grade_ballast_including AS NUMERIC) AS at_grade_ballast_including,
    {{ trim_make_empty_string_null('at_grade_ballast_including_1') }} AS at_grade_ballast_including_1,
    SAFE_CAST(at_grade_in_street_embedded AS NUMERIC) AS at_grade_in_street_embedded,
    {{ trim_make_empty_string_null('at_grade_in_street_embedded_1') }} AS at_grade_in_street_embedded_1,
    SAFE_CAST(below_grade_bored_or_blasted AS NUMERIC) AS below_grade_bored_or_blasted,
    {{ trim_make_empty_string_null('below_grade_bored_or_blasted_1') }} AS below_grade_bored_or_blasted_1,
    SAFE_CAST(below_grade_cut_and_cover AS NUMERIC) AS below_grade_cut_and_cover,
    {{ trim_make_empty_string_null('below_grade_cut_and_cover_1') }} AS below_grade_cut_and_cover_1,
    SAFE_CAST(below_grade_retained_cut AS NUMERIC) AS below_grade_retained_cut,
    {{ trim_make_empty_string_null('below_grade_retained_cut_1') }} AS below_grade_retained_cut_1,
    SAFE_CAST(below_grade_submerged_tube AS NUMERIC) AS below_grade_submerged_tube,
    {{ trim_make_empty_string_null('below_grade_submerged_tube_1') }} AS below_grade_submerged_tube_1,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(controlled_access_high AS NUMERIC) AS controlled_access_high,
    {{ trim_make_empty_string_null('controlled_access_high_1') }} AS controlled_access_high_1,
    SAFE_CAST(double_crossover AS NUMERIC) AS double_crossover,
    {{ trim_make_empty_string_null('double_crossover_q') }} AS double_crossover_q,
    SAFE_CAST(elevated_concrete AS NUMERIC) AS elevated_concrete,
    {{ trim_make_empty_string_null('elevated_concrete_q') }} AS elevated_concrete_q,
    SAFE_CAST(elevated_retained_fill AS NUMERIC) AS elevated_retained_fill,
    {{ trim_make_empty_string_null('elevated_retained_fill_q') }} AS elevated_retained_fill_q,
    SAFE_CAST(elevated_steel_viaduct_or AS NUMERIC) AS elevated_steel_viaduct_or,
    {{ trim_make_empty_string_null('elevated_steel_viaduct_or_1') }} AS elevated_steel_viaduct_or_1,
    SAFE_CAST(exclusive_fixed_guideway AS NUMERIC) AS exclusive_fixed_guideway,
    {{ trim_make_empty_string_null('exclusive_fixed_guideway_1') }} AS exclusive_fixed_guideway_1,
    SAFE_CAST(exclusive_high_intensity AS NUMERIC) AS exclusive_high_intensity,
    {{ trim_make_empty_string_null('exclusive_high_intensity_1') }} AS exclusive_high_intensity_1,
    SAFE_CAST(grade_crossings AS NUMERIC) AS grade_crossings,
    {{ trim_make_empty_string_null('grade_crossings_q') }} AS grade_crossings_q,
    SAFE_CAST(lapped_turnout AS NUMERIC) AS lapped_turnout,
    {{ trim_make_empty_string_null('lapped_turnout_q') }} AS lapped_turnout_q,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(rail_crossings AS NUMERIC) AS rail_crossings,
    {{ trim_make_empty_string_null('rail_crossings_q') }} AS rail_crossings_q,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    SAFE_CAST(single_crossover AS NUMERIC) AS single_crossover,
    {{ trim_make_empty_string_null('single_crossover_q') }} AS single_crossover_q,
    SAFE_CAST(single_turnout AS NUMERIC) AS single_turnout,
    {{ trim_make_empty_string_null('single_turnout_q') }} AS single_turnout_q,
    SAFE_CAST(slip_switch AS NUMERIC) AS slip_switch,
    {{ trim_make_empty_string_null('slip_switch_q') }} AS slip_switch_q,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(total_miles AS NUMERIC) AS total_miles,
    SAFE_CAST(total_track_miles AS NUMERIC) AS total_track_miles,
    {{ trim_make_empty_string_null('total_track_miles_q') }} AS total_track_miles_q,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__track_and_roadway_by_mode
