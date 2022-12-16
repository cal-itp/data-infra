WITH

once_daily_organizations AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__organizations'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        organization_type,
        roles,
        itp_id,
        unnested_ntd_records AS ntd_agency_info_key,
        hubspot_company_record_id,
        alias_ as alias,
        details,
        caltrans_district,
        mobility_services_managed,
        parent_organization,
        website,
        reporting_category,
        funding_programs,
        gtfs_datasets_produced,
        gtfs_static_status,
        gtfs_realtime_status,
        assessment_status = "Yes" AS assessment_status,
        dt AS calitp_extracted_at
    FROM once_daily_organizations
    LEFT JOIN UNNEST(once_daily_organizations.ntd_id) as unnested_ntd_records
)

SELECT * FROM stg_transit_database__organizations
