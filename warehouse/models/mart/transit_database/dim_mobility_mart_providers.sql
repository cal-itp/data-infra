{{ config(materialized='table') }}

-- An Organization (i.e. dim_organizations) can provide multiple different
-- Services (i.e. dim_services). Each Service will have its own funding sources,
-- GTFS feeds, and target counties.

{% set innerDelimiter = "';'" %}

WITH organizations AS (
   SELECT * FROM {{ ref('dim_organizations') }}
   WHERE _is_current
),

services AS (
    SELECT * FROM {{ ref('dim_services') }}
    WHERE _is_current
),

county_geogs AS (
    SELECT * FROM {{ ref('dim_county_geography') }}
    WHERE _is_current
),

orgs_x_hq AS (
    SELECT * FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
    WHERE _is_current
),

services_x_funding AS (
    SELECT * FROM {{ ref('bridge_services_x_funding_programs') }}
    WHERE _is_current
),

gtfs_schedules AS (
    SELECT
        key,
        {{ from_url_safe_base64('base64_url') }} AS schedule_url
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE _is_current
        AND type = 'schedule'
),

-- A faux bridge table that conveniently has organizations mapped to services
-- mapped to GTFS data
orgs_x_services_x_gtfs AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current
),

-- This query will collect every funding source an Organization has via the
-- services it provides.
funding_by_org AS (
    SELECT
        orgs.organization_key AS org_key,
        ARRAY_TO_STRING(
            ARRAY_AGG(
                DISTINCT services_x_funding.funding_program_name
                ORDER BY funding_program_name
            ),
            {{ innerDelimiter }}
        ) AS funding_sources
    FROM
        orgs_x_services_x_gtfs orgs
    INNER JOIN
        services_x_funding ON orgs.service_key = services_x_funding.service_key
    WHERE
        -- We only want funding programs that are numerical in name; i.e. ignore programs like 'Public', 'Caltrans', 'Private'
        REGEXP_CONTAINS(services_x_funding.funding_program_name, '^\\d+$')
    GROUP BY
        orgs.organization_key
),

-- This table has historical data for every year (looks like dating back to
-- 2018), so let's narrow down that table to *just* the most recent year so
-- we don't get duplicate rows for each year.
--
-- We cannot use `_is_current` here because every year is marked as "current"
-- since it's the "current" record for the respective year.
annual_ntd AS (
    SELECT * FROM {{ ref('dim_annual_ntd_agency_information') }}
    WHERE state = "CA"

    -- We only want data from the latest data from NTD. In the rare edge case
    -- that an NTD ID is removed and no longer exists in the current year's
    -- dataset, then replace `DENSE_RANK()` with `ROW_NUMBER()` and add a
    -- `PARTITION BY ntd_id` inside of the `OVER()`.
    QUALIFY DENSE_RANK() OVER(ORDER BY year DESC) = 1
),

gtfs_urls_by_org AS (
    SELECT
        orgs_x_services_x_gtfs.organization_key AS org_key,
        ARRAY_TO_STRING(
            ARRAY_AGG(
                DISTINCT gtfs_schedules.schedule_url
                IGNORE NULLS
                ORDER BY schedule_url
            ),
            {{ innerDelimiter }}
        ) AS gtfs_uris
    FROM orgs_x_services_x_gtfs
    LEFT JOIN
        gtfs_schedules ON orgs_x_services_x_gtfs.schedule_gtfs_dataset_key = gtfs_schedules.key
    GROUP BY
        orgs_x_services_x_gtfs.organization_key
),

serviced_counties_by_org AS (
    SELECT
        orgs.organization_key AS org_key,
        ARRAY_TO_STRING(
            ARRAY_AGG(DISTINCT counties ORDER BY counties),
            {{ innerDelimiter }}
        ) AS operating_counties
    FROM orgs_x_services_x_gtfs orgs
    LEFT JOIN
        services ON services.key = orgs.service_key,
        UNNEST(services.operating_counties) counties
    GROUP BY
        orgs.organization_key
),

mobility_market_providers AS (
    SELECT
        annual_ntd.agency_name AS agency_name,
        annual_ntd.ntd_id AS ntd_id,
        annual_ntd.city AS hq_city,
        orgs_x_hq.county_geography_name AS hq_county,
        serviced_counties_by_org.operating_counties AS counties_served,
        annual_ntd.url AS agency_website,
        county_geogs.caltrans_district AS caltrans_district_id,
        county_geogs.caltrans_district_name AS caltrans_district_name,
        orgs.is_public_entity AS is_public_entity,
        orgs.public_currently_operating AS is_publicly_operating,
        funding_by_org.funding_sources AS funding_sources,
        annual_ntd.voms_do AS on_demand_vehicles_at_max_service,
        annual_ntd.total_voms AS vehicles_at_max_service,
        gtfs_urls_by_org.gtfs_uris AS gtfs_schedule_uris
    FROM
        annual_ntd
    LEFT JOIN
        organizations orgs ON orgs.ntd_id = annual_ntd.ntd_id
    LEFT JOIN
        orgs_x_hq ON orgs.key = orgs_x_hq.organization_key
    LEFT JOIN
        county_geogs ON orgs_x_hq.county_geography_key = county_geogs.key
    LEFT JOIN
        funding_by_org ON funding_by_org.org_key = orgs.key
    LEFT JOIN
        gtfs_urls_by_org ON gtfs_urls_by_org.org_key = orgs.key
    LEFT JOIN
        serviced_counties_by_org ON serviced_counties_by_org.org_key = orgs.key
    ORDER BY
        annual_ntd.ntd_id
)

SELECT * FROM mobility_market_providers
