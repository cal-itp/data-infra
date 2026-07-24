{{
    config(
        materialized='table',
        tags=['tides_reference'],
    )
}}

-- Organization reference for the published TIDES dataset: every organization that appears in the TIDES facts

WITH member_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE source_record_id IN (
        SELECT organization_source_record_id
        FROM {{ ref('tides_publication_organizations') }}
    )
),

bridge_hq_county AS (
    SELECT * FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
),

county_geography AS (
    SELECT * FROM {{ ref('dim_county_geography') }}
),

tides_organizations AS (
    SELECT
        orgs.key,
        orgs.source_record_id,
        orgs.name,
        orgs.organization_type,
        orgs.website,
        orgs.is_public_entity,
        orgs.ntd_id,
        orgs.ntd_agency_info_key,
        orgs.ntd_id_2022,
        orgs.rtpa_key,
        orgs.rtpa_name,
        orgs.mpo_key,
        orgs.mpo_name,
        orgs.public_currently_operating,
        orgs.public_currently_operating_fixed_route,
        county_geography.caltrans_district,
        county_geography.caltrans_district_name,
        orgs._valid_from,
        orgs._valid_to,
        orgs._is_current
    FROM member_organizations AS orgs
    LEFT JOIN bridge_hq_county
        ON bridge_hq_county.organization_key = orgs.key
            AND bridge_hq_county._valid_from < orgs._valid_to
            AND orgs._valid_from < bridge_hq_county._valid_to
    LEFT JOIN county_geography
        ON county_geography.key = bridge_hq_county.county_geography_key
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY orgs.key
        ORDER BY bridge_hq_county._valid_from DESC
    ) = 1
)

SELECT * FROM tides_organizations
