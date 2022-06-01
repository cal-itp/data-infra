{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'california_transit__organizations'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT
        organization_id AS id,
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
