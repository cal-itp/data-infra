WITH staging_agency_information AS (
    SELECT *
    FROM {{ ref('stg_ntd__2022_agency_information') }}
),

dim_organizations AS (

    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current

),

dim_2022_agency_information AS (
    SELECT
        staging_agency_information.*,
        dim_organizations.caltrans_district
    FROM staging_agency_information
    LEFT JOIN dim_organizations
        ON staging_agency_information.ntd_id = dim_organizations.ntd_id_2022
)

SELECT
    number_of_state_counties,
    tam_tier,
    personal_vehicles,
    uza_name,
    tribal_area_name,
    service_area_sq_miles,
    voms_do,
    url,
    region,
    state_admin_funds_expended,
    zip_code_ext,
    zip_code,
    ueid,
    address_line_2,
    number_of_counties_with_service,
    reporter_acronym,
    original_due_date,
    sq_miles,
    address_line_1,
    p_o__box,
    fy_end_date,
    service_area_pop,
    state,
    subrecipient_type,
    population,
    reporting_module,
    volunteer_drivers,
    doing_business_as,
    reporter_type,
    legacy_ntd_id,
    total_voms,
    primary_uza_uace_code,
    reported_by_name,
    fta_recipient_id,
    city,
    voms_pt,
    organization_type,
    agency_name,
    ntd_id,
    reported_by_ntd_id,
    density,
    state_parent_ntd_id,
    caltrans_district,
    dt,
    execution_ts
FROM dim_2022_agency_information
