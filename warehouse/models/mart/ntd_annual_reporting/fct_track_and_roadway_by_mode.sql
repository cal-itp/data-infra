WITH staging_track_and_roadway_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__track_and_roadway_by_mode') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('3c780a597dde8eaf20b9f658fe9c7b35','6aeb8a08568bae57b8a3a824d93b987d','0b3fcf1a1567f5fc197678ae4fd8eb4e')
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

fct_track_and_roadway_by_mode AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
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
        stg.mode_voms,
        stg.organization_type,
        stg.primary_uza_population,
        stg.rail_crossings,
        stg.rail_crossings_q,
        stg.reporter_type,
        stg.single_crossover,
        stg.single_crossover_q,
        stg.single_turnout,
        stg.single_turnout_q,
        stg.slip_switch,
        stg.slip_switch_q,
        stg.total_miles,
        stg.total_track_miles,
        stg.total_track_miles_q,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_track_and_roadway_by_mode AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_track_and_roadway_by_mode
