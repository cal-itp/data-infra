{{ config(materialized='table') }}

WITH latest_organizations AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__organizations'),
        order_by = 'dt DESC'
        ) }}
),

dim_organizations AS (
    SELECT
        key,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        website,
        reporting_category,
        ntd_agency_info_key,
        hubspot_company_record_id,
        gtfs_static_status,
        gtfs_realtime_status,
        assessment_status,
        alias,
        dt
    FROM latest_organizations
)

SELECT * FROM dim_organizations
