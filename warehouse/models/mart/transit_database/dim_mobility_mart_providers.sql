{{ config(materialized='table') }}

-- An Organization (i.e. dim_organizations) can provide multiple different
-- Services (i.e. dim_services). Each Service will have its own funding sources,
-- GTFS feeds, and target counties.

WITH organizations AS (
   SELECT * FROM {{ ref('dim_organizations') }}
   WHERE _is_current
),

services AS (
    SELECT * FROM {{ ref('dim_services')}}
    WHERE _is_current
),

county_geogs AS (
    SELECT * FROM {{ ref('dim_county_geography') }}
)

orgs_hq_bridge AS (
    SELECT * FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
)

orgs_services_bridge AS (
   SELECT * FROM {{ ref('bridge_organizations_x_services_managed') }}
   WHERE _is_current
),

services_funding_bridge AS (
   SELECT * FROM {{ ref('bridge_services_x_funding_programs') }}
   WHERE _is_current
),

gtfs_services AS (
   SELECT * FROM {{ ref('dim_gtfs_service_data') }}
   WHERE _is_current
),

gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
   WHERE _is_current
)

-- This query will collect every funding source an Organization has via the
-- services it provides.
funding_by_organization AS (
    SELECT
        orgs.key AS org_key,
        ARRAY_AGG(services_funding_bridge.funding_program_name) AS funding_sources
    FROM
        organizations orgs
    INNER JOIN
        orgs_services_bridge ON orgs_services_bridge.org_key = orgs.key
    INNER JOIN
        services_funding_bridge ON orgs_services_bridge.service_key = services_funding_bridge.service_key
    GROUP BY
        orgs.key
),

-- This table has historical data for every year (looks like dating back to
-- 2018), so let's narrow down that table to *just* the most recent year so
-- we don't get duplicate rows for each year.
--
-- We cannot use `_is_current` here because every year is marked as "current"
-- since it's the "current" record for the respective year.
annual_ntd AS (
    SELECT *
    FROM mart_ntd.dim_annual_ntd_agency_information
    WHERE state = "CA"

    -- We only want data from the latest data from NTD. In the rare edge case
    -- that an NTD ID is removed and no longer exists in the current year's
    -- dataset, then replace `DENSE_RANK()` with `ROW_NUMBER()` and add a
    -- `PARTITION BY ntd_id` inside of the `OVER()`.
    QUALIFY DENSE_RANK() OVER(ORDER BY year DESC) = 1
),

gtfs_data_by_organization AS (
    SELECT
        orgs.key AS org_key,
        ARRAY_AGG(gtfs_datasets.uri) AS gtfs_uris
    FROM organizations orgs
    LEFT JOIN
        orgs_services_bridge ON orgs.key = orgs_services_bridge.org_key
    LEFT JOIN
        gtfs_services ON orgs_services_bridge.service_key = gtfs_services.service_key
    LEFT JOIN
        gtfs_datasets ON gtfs_services.gtfs_dataset_key = gtfs_datasets.key
    WHERE
        orgs.public_currently_operating IS TRUE
        AND gtfs_services.customer_facing IS TRUE
        -- We only want to track schedule feeds for right now
        AND gtfs_datasets.type = 'schedule'
    GROUP BY
        orgs.key
),

serviced_counties_by_organization AS (
    SELECT
        orgs.key AS org_key,
        ARRAY_CONCAT_AGG(services.operating_counties) AS operating_counties
    FROM organizations orgs
    LEFT JOIN
        orgs_services_bridge orgs_services_bridge ON orgs_services_bridge.org_key = orgs.key
    LEFT JOIN
        services ON services.key = orgs_services_bridge.service_key
    GROUP BY
        orgs.key
),

mobility_market_providers AS (
    SELECT
        annual_ntd.agency_name AS agency_name,
        annual_ntd.ntd_id AS ntd_id,
        annual_ntd.city AS hq_city,
        orgs_hq_bridge.county_geography_name AS hq_county,
        ARRAY(
            SELECT DISTINCT
                county
            FROM UNNEST(serviced_counties_by_organization.operating_counties) county
            ORDER BY county
        ) AS counties_served,
        annual_ntd.url AS agency_website,
        county_geog.caltrans_district AS caltrans_district_id,
        county_geog.caltrans_district_name AS caltrans_district_name,
        orgs.is_public_entity AS is_public_entity,
        orgs.public_currently_operating AS is_publicly_operating,
        ARRAY(
            SELECT DISTINCT
            source
            FROM UNNEST(funding_by_organization.funding_sources) source
            ORDER BY source
        ) AS funding_sources,
        annual_ntd.voms_do AS on_demand_vehicles_at_max_service,
        annual_ntd.total_voms AS vehicles_at_max_service,
        ARRAY(
            SELECT DISTINCT
            uris
            FROM UNNEST(gtfs_data_by_organization.gtfs_uris) uris
            ORDER BY uris
        ) AS gtfs_schedule_uris
    FROM
        annual_ntd
    LEFT JOIN
        organizations orgs ON orgs.ntd_id = annual_ntd.ntd_id
    LEFT JOIN
        orgs_hq_bridge ON orgs.key = orgs_hq_bridge.org_key
    LEFT JOIN
        county_geogs ON orgs_hq_bridge.county_geography_key = county_geogs.key
    LEFT JOIN
        funding_by_organization ON funding_by_organization.org_key = orgs.key
    LEFT JOIN
        gtfs_data_by_organization ON gtfs_data_by_organization.org_key = orgs.key
    LEFT JOIN
        serviced_counties_by_organization ON serviced_counties_by_organization.org_key = orgs.key
    ORDER BY
        annual_ntd.ntd_id
)

SELECT * FROM mobility_market_providers
