{{ config(materialized='view') }}

WITH intermediate_unioned_agency_information AS (
    SELECT *
    FROM {{ ref('int_ntd__unioned_agency_information') }}
),

dim_annual_agency_information AS (
    SELECT
        key,
        year,
        ntd_id,
        state_parent_ntd_id,
        agency_name,
        reporter_acronym,
        doing_business_as,
        division_department,
        legacy_ntd_id,
        reported_by_ntd_id,
        reported_by_name,
        reporter_type,
        reporting_module,
        organization_type,
        subrecipient_type,
        fy_end_date,
        original_due_date,
        address_line_1,
        address_line_2,
        p_o__box,
        city,
        state,
        zip_code,
        zip_code_ext,
        region,
        url,
        fta_recipient_id,
        ueid,
        service_area_sq_miles,
        service_area_pop,
        primary_uza_code,
        primary_uza_name,
        tribal_area_name,
        population,
        density,
        sq_miles,
        voms_do,
        voms_pt,
        total_voms,
        volunteer_drivers,
        personal_vehicles,
        tam_tier,
        number_of_state_counties,
        number_of_counties_with_service,
        state_admin_funds_expended,
        _valid_from,
        _valid_to,
        _is_current,
    FROM intermediate_unioned_agency_information
)

SELECT * FROM dim_annual_agency_information
