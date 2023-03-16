{{ config(materialized='table') }}

WITH dim AS (
    SELECT * FROM {{ ref('int_transit_database__organizations_dim') }}
),

ntd_agency_to_organization AS (
    SELECT * FROM {{ ref('ntd_agency_to_organization') }}
),

dim_annual_database_agency_information AS (
    SELECT * FROM {{ ref('dim_annual_database_agency_information') }}
),

bridge_organizations_x_county_geography AS (
    SELECT * FROM {{ ref('bridge_organizations_x_county_geography') }}
),

dim_organizations AS (
    SELECT
        -- key
        dim.key,
        dim.source_record_id,
        ntd.key AS annual_database_agency_information_2021_key,
        -- attributes
        dim.name,
        dim.organization_type,
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
        geography_bridge.name AS hq_county_geography,
        dim._is_current,
        dim._valid_from,
        dim._valid_to
    FROM dim
    LEFT JOIN ntd_agency_to_organization ntd_to_org
        ON dim.source_record_id = ntd_to_org.organization_record_id
    LEFT JOIN dim_annual_database_agency_information AS ntd
        -- TODO: make this historical and use a bridge table
        ON ntd_to_org.ntd_id = ntd.ntd_id
        AND ntd._is_current
        AND ntd.year = 2021
    LEFT JOIN bridge_organizations_x_county_geography AS geography_bridge
        ON dim.source_record_id = geography_bridge.source_record_id
)

SELECT * FROM dim_organizations
