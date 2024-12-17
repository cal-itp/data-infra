WITH external_track_and_roadway_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__track_and_roadway_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_track_and_roadway_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__track_and_roadway_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('max_agency') }} AS max_agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS max_city,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS max_state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST(sum_at_grade_ballast_including AS NUMERIC) AS sum_at_grade_ballast_including,
    SAFE_CAST(sum_at_grade_in_street_embedded AS NUMERIC) AS sum_at_grade_in_street_embedded,
    SAFE_CAST(sum_below_grade_bored_or_blasted AS NUMERIC) AS sum_below_grade_bored_or_blasted,
    SAFE_CAST(sum_below_grade_cut_and_cover AS NUMERIC) AS sum_below_grade_cut_and_cover,
    SAFE_CAST(sum_below_grade_retained_cut AS NUMERIC) AS sum_below_grade_retained_cut,
    SAFE_CAST(sum_below_grade_submerged_tube AS NUMERIC) AS sum_below_grade_submerged_tube,
    SAFE_CAST(sum_controlled_access_high AS NUMERIC) AS sum_controlled_access_high,
    SAFE_CAST(sum_double_crossover AS NUMERIC) AS sum_double_crossover,
    SAFE_CAST(sum_elevated_concrete AS NUMERIC) AS sum_elevated_concrete,
    SAFE_CAST(sum_elevated_retained_fill AS NUMERIC) AS sum_elevated_retained_fill,
    SAFE_CAST(sum_elevated_steel_viaduct_or AS NUMERIC) AS sum_elevated_steel_viaduct_or,
    SAFE_CAST(sum_exclusive_fixed_guideway AS NUMERIC) AS sum_exclusive_fixed_guideway,
    SAFE_CAST(sum_exclusive_high_intensity AS NUMERIC) AS sum_exclusive_high_intensity,
    SAFE_CAST(sum_grade_crossings AS NUMERIC) AS sum_grade_crossings,
    SAFE_CAST(sum_lapped_turnout AS NUMERIC) AS sum_lapped_turnout,
    SAFE_CAST(sum_rail_crossings AS NUMERIC) AS sum_rail_crossings,
    SAFE_CAST(sum_single_crossover AS NUMERIC) AS sum_single_crossover,
    SAFE_CAST(sum_single_turnout AS NUMERIC) AS sum_single_turnout,
    SAFE_CAST(sum_slip_switch AS NUMERIC) AS sum_slip_switch,
    SAFE_CAST(sum_total_miles AS NUMERIC) AS sum_total_miles,
    SAFE_CAST(sum_total_track_miles AS NUMERIC) AS sum_total_track_miles,
    dt,
    execution_ts
FROM stg_ntd__track_and_roadway_by_agency
