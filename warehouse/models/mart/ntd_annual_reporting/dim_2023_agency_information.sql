WITH staging_agency_information AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_agency_information') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

dim_2023_agency_information AS (
    SELECT
        stg.number_of_state_counties,
        stg.tam_tier,
        stg.personal_vehicles,
        stg.uza_name,
        stg.tribal_area_name,
        stg.service_area_sq_miles,
        stg.voms_do,
        stg.url,
        stg.region,
        stg.state_admin_funds_expended,
        stg.zip_code_ext,
        stg.zip_code,
        stg.ueid,
        stg.address_line_2,
        stg.number_of_counties_with_service,
        stg.reporter_acronym,
        stg.original_due_date,
        stg.sq_miles,
        stg.address_line_1,
        stg.p_o__box,
        stg.division_department,
        stg.fy_end_date,
        stg.service_area_pop,
        stg.state,
        stg.subrecipient_type,
        stg.primary_uza_uace_code,
        stg.reported_by_name,
        stg.population,
        stg.reporting_module,
        stg.volunteer_drivers,
        stg.doing_business_as,
        stg.reporter_type,
        stg.legacy_ntd_id,
        stg.total_voms,
        stg.fta_recipient_id,
        stg.city,
        stg.voms_pt,
        stg.organization_type,
        stg.agency_name,
        stg.ntd_id,
        stg.reported_by_ntd_id,
        stg.density,
        stg.state_parent_ntd_id,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_agency_information AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM dim_2023_agency_information
