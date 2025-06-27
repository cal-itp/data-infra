WITH staging_track_and_roadway_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_agency') }}
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

fct_track_and_roadway_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

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
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_track_and_roadway_by_agency
