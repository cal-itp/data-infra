{{ config(materialized='table') }}

WITH int_transit_database__ntd_agency_info_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__ntd_agency_info_dim') }}
),

dim_ntd_agency_info AS (
    SELECT
        key,
        source_record_id,
        ntd_id,
        legacy_ntd_id,
        ntd_agency_name,
        reporter_acronym,
        doing_business_as,
        reporter_status,
        reporter_type,
        reporting_module,
        organization_type,
        reported_by_ntd_id,
        reported_by_name,
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
        duns_number,
        service_area_sq_miles,
        service_area_pop,
        primary_uza,
        uza_name,
        tribal_area_name,
        population,
        density,
        sq_miles,
        voms_do,
        voms_pt,
        total_voms,
        volunteer_drivers,
        personal_vehicles,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__ntd_agency_info_dim
)

SELECT * FROM dim_ntd_agency_info
