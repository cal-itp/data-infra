

WITH
once_daily_organizations AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__organizations'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        mobility_services_managed,
        parent_organization,
        website,
        dt AS calitp_extracted_at
    FROM once_daily_organizations
)

SELECT * FROM stg_transit_database__organizations
