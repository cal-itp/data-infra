{{ config(materialized='table') }}

WITH int_organizations_dim AS (
    SELECT * FROM {{ ref('int_transit_database__organizations_dim') }}
),

<<<<<<< HEAD
-- This is deprecated, what replaced the source of truth for ntd_id < '2023-05-23' that was previously found in ntd_to_org.ntd_id ??
-- ntd_agency_to_organization AS (
--     SELECT * FROM {{ ref('_deprecated__ntd_agency_to_organization') }}
-- ),

mpo_rtpa AS (
=======
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
>>>>>>> 53e471e4 (enrich dim_organizations with caltrans district info from improved pattern, remove deprecated airtable caltrans district columns from stg/int tables)
    SELECT
        key,
        source_record_id,
        name
    FROM dim
    WHERE
        organization_type = "MPO/RTPA"
        AND _is_current = TRUE
),

dim_organizations AS (
    SELECT
        dim.key,
        dim.source_record_id,
        dim.name,
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
        mr_rtpa.key AS rtpa_key,
        mr_rtpa.name AS rtpa_name,
        mr_mpo.key AS mpo_key,
        mr_mpo.name AS mpo_name,
        public_currently_operating,
        public_currently_operating_fixed_route,
        _is_current,
        _valid_from,
        _valid_to

<<<<<<< HEAD
    FROM dim
    LEFT JOIN ntd_agency_to_organization ntd_to_org
        ON source_record_id = ntd_to_org.organization_record_id
    LEFT JOIN mpo_rtpa mr_rtpa ON dim.rtpa = mr_rtpa.source_record_id
    LEFT JOIN mpo_rtpa mr_mpo ON dim.mpo = mr_mpo.source_record_id
=======
    FROM join_caltrans_district
>>>>>>> 53e471e4 (enrich dim_organizations with caltrans district info from improved pattern, remove deprecated airtable caltrans district columns from stg/int tables)

)

SELECT * FROM dim_organizations
