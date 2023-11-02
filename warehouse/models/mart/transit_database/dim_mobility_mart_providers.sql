-- An Organization (i.e. dim_organizations) can provide multiple different
-- Services (i.e. dim_services). Each Service will have its own funding sources,
-- GTFS feeds, and target counties.

-- This query will collect every funding source an Organization has via the
-- services it provides.
WITH funding_by_organization AS (
    SELECT
        orgs.key AS organization_key,
        ARRAY_AGG(services_x_funding.funding_program_name) AS funding_sources
    FROM
        mart_transit_database.dim_organizations orgs
    INNER JOIN
        mart_transit_database.bridge_organizations_x_services_managed orgs_x_services ON orgs_x_services.organization_key = orgs.key AND orgs_x_services._is_current IS TRUE
    INNER JOIN
        mart_transit_database.bridge_services_x_funding_programs services_x_funding ON orgs_x_services.service_key = services_x_funding.service_key AND services_x_funding._is_current IS TRUE
    WHERE
        orgs._is_current IS TRUE
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
    WHERE
        year = (SELECT MAX(year) FROM mart_ntd.dim_annual_ntd_agency_information) AND
        state = 'CA'
),

gtfs_data_by_organization AS (
    SELECT
        orgs.key AS organization_key,
        ARRAY_AGG(gtfs_datasets.uri) AS gtfs_uris
    FROM mart_transit_database.dim_organizations orgs
    LEFT JOIN
        mart_transit_database.bridge_organizations_x_services_managed orgs_x_services ON orgs.key = orgs_x_services.organization_key
    LEFT JOIN
        mart_transit_database.dim_gtfs_service_data gtfs_service ON orgs_x_services.service_key = gtfs_service.service_key
    LEFT JOIN
        mart_transit_database.dim_gtfs_datasets gtfs_datasets ON gtfs_service.gtfs_dataset_key = gtfs_datasets.key
    WHERE
        orgs._is_current IS TRUE AND
        orgs.public_currently_operating IS TRUE AND
        gtfs_service._is_current IS TRUE AND
        gtfs_service.customer_facing IS TRUE AND
        gtfs_datasets._is_current IS TRUE AND
        -- We only want to track schedule feeds for right now
        gtfs_datasets.type = 'schedule'
    GROUP BY
        orgs.key
),

serviced_counties_by_organization AS (
    SELECT
        orgs.key AS organization_key,
        ARRAY_CONCAT_AGG(services.operating_counties) AS operating_counties
    FROM mart_transit_database.dim_organizations orgs
    LEFT JOIN
        mart_transit_database.bridge_organizations_x_services_managed orgs_x_services ON orgs_x_services.organization_key = orgs.key
    LEFT JOIN
        mart_transit_database.dim_services services ON services.key = orgs_x_services.service_key
    WHERE
        orgs._is_current IS TRUE AND
        services._is_current IS TRUE
    GROUP BY
        orgs.key
),

mobility_market_providers AS (
    SELECT
        annual_ntd.agency_name AS agency_name,
        annual_ntd.ntd_id AS ntd_id,
        annual_ntd.city AS hq_city,
        orgs_x_hq.county_geography_name AS hq_county,
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
        mart_transit_database.dim_organizations orgs ON orgs.ntd_id = annual_ntd.ntd_id AND orgs._is_current IS TRUE
    LEFT JOIN
        mart_transit_database.bridge_organizations_x_headquarters_county_geography orgs_x_hq ON orgs.key = orgs_x_hq.organization_key
    LEFT JOIN
        mart_transit_database.dim_county_geography county_geog ON orgs_x_hq.county_geography_key = county_geog.key
    LEFT JOIN
        funding_by_organization ON funding_by_organization.organization_key = orgs.key
    LEFT JOIN
        gtfs_data_by_organization ON gtfs_data_by_organization.organization_key = orgs.key
    LEFT JOIN
        serviced_counties_by_organization ON serviced_counties_by_organization.organization_key = orgs.key
    ORDER BY
        annual_ntd.ntd_id
)

SELECT * FROM mobility_market_providers
