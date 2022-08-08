

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
        {{ trim_make_empty_string_null(column_name = "name") }},
        organization_type,
        roles,
        itp_id,
        ntp_id,
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
        dt AS calitp_extracted_at
    FROM once_daily_organizations
)

SELECT * FROM stg_transit_database__organizations
