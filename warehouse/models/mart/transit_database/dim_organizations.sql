{{ config(materialized='table') }}

WITH dim AS (
    SELECT * FROM {{ ref('int_transit_database__organizations_dim') }}
),

mpo_rtpa AS (
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
            -- is this substitution appropriate?
            ELSE ntd_id
            -- ELSE ntd_to_org.ntd_id
        END AS ntd_id,
        -- how to appropriately use ntd_agency_info_key?
        ntd_agency_info_key,
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

    FROM dim
    LEFT JOIN mpo_rtpa mr_rtpa ON dim.rtpa = mr_rtpa.source_record_id
    LEFT JOIN mpo_rtpa mr_mpo ON dim.mpo = mr_mpo.source_record_id

)

SELECT * FROM dim_organizations
