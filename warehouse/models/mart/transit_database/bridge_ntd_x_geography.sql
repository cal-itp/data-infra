{{ config(materialized='table') }}

WITH dim_county_geography AS (
    SELECT DISTINCT
        key,
        name,
        caltrans_district,
        caltrans_district_name,
    FROM {{ ref('dim_county_geography') }}
),

bridge_org_county AS (
    SELECT
        organization_key,
        county_geography_key,
    FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
),

orgs_with_geog AS (
    SELECT
        dim_organizations.source_record_id AS organization_source_record_id,
        MAX(dim_organizations.name) AS organization_name,

        MAX(dim_county_geography.name) AS county_name,
        MAX(dim_county_geography.caltrans_district) AS caltrans_district,
        MAX(dim_county_geography.caltrans_district_name) AS caltrans_district_name,

        MAX(dim_organizations.ntd_id) AS ntd_id,
        MAX(dim_organizations.ntd_id_2022) AS ntd_id_2022,
        MAX(dim_organizations.rtpa_name) AS rtpa_name,
        MAX(dim_organizations.mpo_name) AS mpo_name,

    FROM dim_organizations
    INNER JOIN bridge_org_county
        -- join on organization_key will result in some values with the same
        -- organization_source_record_id not having ntd_id or rtpa filled in
        ON dim_organizations.key = bridge_org_county.organization_key
    INNER JOIN dim_county_geography
        ON bridge_org_county.county_geography_key = dim_county_geography.key
    GROUP BY organization_source_record_id
),

bridge_split_out_scag AS (
    SELECT
        *,
        CASE
            WHEN county_name = "Ventura" THEN "Ventura County Transportation Commission"
            WHEN county_name = "Los Angeles" THEN "Los Angeles County Metropolitan Transportation Authority"
            WHEN county_name = "San Bernardino" THEN "San Bernardino County Transportation Authority"
            WHEN county_name = "Riverside" THEN "Riverside County Transportation Commission"
            WHEN county_name = "Orange" THEN "Orange County Transportation Authority"
            WHEN county_name = "Imperial" THEN "Imperial County Transportation Commission"
            ELSE rtpa_name
        END AS rtpa_name_split
    FROM orgs_with_geog
    WHERE ntd_id_2022 IS NOT NULL
    -- remove orgs that do not have ntd_id populated
)

SELECT * FROM bridge_split_out_scag
