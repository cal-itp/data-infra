WITH staging_track_and_roadway_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_agency') }}
),

fct_track_and_roadway_by_agency AS (
    SELECT *
    FROM staging_track_and_roadway_by_agency
)

SELECT
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_at_grade_ballast_including,
    sum_at_grade_in_street_embedded,
    sum_below_grade_bored_or_blasted,
    sum_below_grade_cut_and_cover,
    sum_below_grade_retained_cut,
    sum_below_grade_submerged_tube,
    sum_controlled_access_high,
    sum_double_crossover,
    sum_elevated_concrete,
    sum_elevated_retained_fill,
    sum_elevated_steel_viaduct_or,
    sum_exclusive_fixed_guideway,
    sum_exclusive_high_intensity,
    sum_grade_crossings,
    sum_lapped_turnout,
    sum_rail_crossings,
    sum_single_crossover,
    sum_single_turnout,
    sum_slip_switch,
    sum_total_miles,
    sum_total_track_miles,
    dt,
    execution_ts
FROM fct_track_and_roadway_by_agency
