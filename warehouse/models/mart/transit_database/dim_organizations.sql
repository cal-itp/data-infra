{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

dim_organizations AS (
    SELECT
        key,
        source_record_id,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        website,
        reporting_category,
        hubspot_company_record_id,
        gtfs_static_status,
        gtfs_realtime_status,
        assessment_status,
        manual_check__contact_on_website,
        alias,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_organizations
