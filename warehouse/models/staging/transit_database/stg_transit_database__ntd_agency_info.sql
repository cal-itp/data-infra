

WITH
once_daily_ntd_agency_info AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__ntd_agency_info'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__ntd_agency_info AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "ntd_id") }},
        legacy_ntd_id,
        agency_name,
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
        unnested_organizations AS organization_key,
        time,
        dt AS calitp_extracted_at
    FROM once_daily_ntd_agency_info
    LEFT JOIN UNNEST(once_daily_ntd_agency_info.organizations) AS unnested_organizations
)

SELECT * FROM stg_transit_database__ntd_agency_info
