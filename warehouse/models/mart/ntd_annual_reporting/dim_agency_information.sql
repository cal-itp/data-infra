WITH intermediate_unioned_agency_information AS (
    SELECT *
    FROM {{ ref('int_ntd__unioned_agency_information') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

dim_agency_information AS (
    SELECT
        int.key,
        int.agency_name,
        int.ntd_id,
        int.year,
        int.city,
        int.state,
        int.state_parent_ntd_id,
        int.reporter_acronym,
        int.doing_business_as,
        int.division_department,
        int.legacy_ntd_id,
        int.reported_by_ntd_id,
        int.reported_by_name,
        int.reporter_type,
        int.reporting_module,
        int.organization_type,
        int.subrecipient_type,
        int.fy_end_date,
        int.original_due_date,
        int.address_line_1,
        int.address_line_2,
        int.p_o__box,
        int.zip_code,
        int.zip_code_ext,
        int.region,
        int.url,
        int.fta_recipient_id,
        int.ueid,
        int.service_area_sq_miles,
        int.service_area_pop,
        int.primary_uza_code,
        int.primary_uza_name,
        int.tribal_area_name,
        int.population,
        int.density,
        int.sq_miles,
        int.voms_do,
        int.voms_pt,
        int.total_voms,
        int.volunteer_drivers,
        int.personal_vehicles,
        int.tam_tier,
        int.number_of_state_counties,
        int.number_of_counties_with_service,
        int.state_admin_funds_expended,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int._valid_from,
        int._valid_to,
        int._is_current
    FROM intermediate_unioned_agency_information as int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM dim_agency_information
