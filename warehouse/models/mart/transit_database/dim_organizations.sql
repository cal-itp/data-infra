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

dim_organizations AS (
    SELECT

        -- key
        dim.key,
        dim.source_record_id,

        ntd.key AS annual_database_agency_information_2021_key,

        -- attributes
        dim.name,
        dim.organization_type,
        dim.roles,
        dim.itp_id,
        dim.details,
        dim.caltrans_district,
        dim.website,
        dim.reporting_category,
        dim.hubspot_company_record_id,
        dim.gtfs_static_status,
        dim.gtfs_realtime_status,
        dim.assessment_status,
        dim.manual_check__contact_on_website,
        dim.alias,

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
)

SELECT * FROM dim_organizations
