WITH staging_agency_information AS (
    SELECT *
    FROM {{ ref('stg_ntd__2022_agency_information') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district,
        caltrans_district_name
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

dim_2022_agency_information AS (
    SELECT
        agency.number_of_state_counties,
        agency.tam_tier,
        agency.personal_vehicles,
        agency.uza_name,
        agency.tribal_area_name,
        agency.service_area_sq_miles,
        agency.voms_do,
        agency.url,
        agency.region,
        agency.state_admin_funds_expended,
        agency.zip_code_ext,
        agency.zip_code,
        agency.ueid,
        agency.address_line_2,
        agency.number_of_counties_with_service,
        agency.reporter_acronym,
        agency.original_due_date,
        agency.sq_miles,
        agency.address_line_1,
        agency.p_o__box,
        agency.fy_end_date,
        agency.service_area_pop,
        agency.state,
        agency.subrecipient_type,
        agency.population,
        agency.reporting_module,
        agency.volunteer_drivers,
        agency.doing_business_as,
        agency.reporter_type,
        agency.legacy_ntd_id,
        agency.total_voms,
        agency.primary_uza_uace_code,
        agency.reported_by_name,
        agency.fta_recipient_id,
        agency.city,
        agency.voms_pt,
        agency.organization_type,
        agency.agency_name,
        agency.ntd_id,
        agency.reported_by_ntd_id,
        agency.density,
        agency.state_parent_ntd_id,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        agency.dt,
        agency.execution_ts
    FROM staging_agency_information AS agency
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM dim_2022_agency_information
