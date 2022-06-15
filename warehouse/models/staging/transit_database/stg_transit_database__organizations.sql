{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__organizations'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT
        organization_id AS key,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        mobility_services_managed,
        parent_organization,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__organizations
