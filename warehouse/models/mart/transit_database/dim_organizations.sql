{{ config(materialized='table') }}

WITH int_organizations_dim AS (
    SELECT * FROM {{ ref('int_transit_database__organizations_dim') }}
),

bridge_organizations_x_headquarters_county_geography AS (
    SELECT * FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
),

dim_county_geography AS (
    SELECT * FROM {{ ref('dim_county_geography') }}
),

join_caltrans_district AS (
    SELECT
        int_organizations_dim.*,
        dim_county_geography.caltrans_district,
        dim_county_geography.caltrans_district_name
    FROM int_organizations_dim
    LEFT JOIN bridge_organizations_x_headquarters_county_geography ON int_organizations_dim.key = bridge_organizations_x_headquarters_county_geography.organization_key
        LEFT JOIN dim_county_geography ON bridge_organizations_x_headquarters_county_geography.county_geography_key = dim_county_geography.key
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
        caltrans_district_name,
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
            ELSE ntd_agency_info_key
        END AS ntd_id,
        ntd_id_2022,
        public_currently_operating,
        public_currently_operating_fixed_route,
        _is_current,
        _valid_from,
        _valid_to

    FROM join_caltrans_district

)

SELECT * FROM dim_organizations
