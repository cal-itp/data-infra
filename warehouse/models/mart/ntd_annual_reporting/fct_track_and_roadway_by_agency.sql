WITH staging_track_and_roadway_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_track_and_roadway_by_agency AS (
    SELECT
        stg.max_agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.max_city AS city,
        stg.max_state AS state,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_at_grade_ballast_including,
        stg.sum_at_grade_in_street_embedded,
        stg.sum_below_grade_bored_or_blasted,
        stg.sum_below_grade_cut_and_cover,
        stg.sum_below_grade_retained_cut,
        stg.sum_below_grade_submerged_tube,
        stg.sum_controlled_access_high,
        stg.sum_double_crossover,
        stg.sum_elevated_concrete,
        stg.sum_elevated_retained_fill,
        stg.sum_elevated_steel_viaduct_or,
        stg.sum_exclusive_fixed_guideway,
        stg.sum_exclusive_high_intensity,
        stg.sum_grade_crossings,
        stg.sum_lapped_turnout,
        stg.sum_rail_crossings,
        stg.sum_single_crossover,
        stg.sum_single_turnout,
        stg.sum_slip_switch,
        stg.sum_total_miles,
        stg.sum_total_track_miles,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_track_and_roadway_by_agency
