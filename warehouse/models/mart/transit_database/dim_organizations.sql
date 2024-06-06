{{ config(materialized='table') }}

WITH dim AS (
    SELECT * FROM {{ ref('int_transit_database__organizations_dim') }}
),

ntd_agency_to_organization AS (
    SELECT * FROM {{ ref('_deprecated__ntd_agency_to_organization') }}
),


bridge_ntd_organization AS (
    SELECT
        CAST(ntd_id AS STRING) as test_ntd_id,
        source_record_id
    FROM {{ ref('ntd_id_to_source_record_id') }}
),

dim_organizations AS (
    SELECT
        key,
        COALESCE(dim.source_record_id, bridge_ntd_organization.source_record_id) AS source_record_id,
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
        assessment_status AS _deprecated__assessment_status,
        manual_check__contact_on_website,
        alias,
        is_public_entity,
        -- use same May 23, 2023 cutover date as `assessment_status` --> `public_currently_operating` in downstream models for consistency
        CASE
            WHEN _valid_from >= '2023-05-23' THEN raw_ntd_id
            ELSE ntd_to_org.ntd_id
        END AS ntd_id,
        IF(LENGTH(ntd_id) >= 10,
            SUBSTR(ntd_id, -5),
            ntd_id) AS ntd_id_2022,
        test_ntd_id,
        public_currently_operating,
        public_currently_operating_fixed_route,
        _is_current,
        _valid_from,
        _valid_to

    FROM dim
    LEFT JOIN ntd_agency_to_organization AS ntd_to_org
        ON source_record_id = ntd_to_org.organization_record_id
    LEFT JOIN bridge_ntd_organization
        ON dim.source_record_id = bridge_ntd_organization.source_record_id
)

SELECT * FROM dim_organizations
