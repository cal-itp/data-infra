DECLARE innerDelimiter STRING DEFAULT ';';

-- Some orgs have multiple funding sources, so preformat it using a delimiter
WITH program_funding AS (
    SELECT
        organization_key,
        STRING_AGG(funding_program_name, innerDelimiter) AS funding_programs
    FROM mart_transit_database.bridge_organizations_x_funding_programs funding
    WHERE funding._is_current
    GROUP BY organization_key
),

-- This table has historical data for every year (looks like dating back to
-- 2018), so let's narrow down that table to *just* the most recent year so
-- we don't get duplicate rows for each year.
annual_ntd AS (
    SELECT *
    FROM mart_ntd.dim_annual_ntd_agency_information
    WHERE year = (SELECT MAX(year) FROM mart_ntd.dim_annual_ntd_agency_information)
),

gtfs_data AS (
    SELECT
        orgs.key,
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
        gtfs_datasets.type = 'schedule'
    GROUP BY
        orgs.key
),

serviced_counties AS (
    SELECT
        orgs.key AS key,
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

dim_mobility_mart_providers AS (
    SELECT
        orgs.name AS agency_name,
        orgs.ntd_id AS ntd_id,
        annual_ntd.city AS hq_city,
        orgs_x_hq.county_geography_name AS hq_county,
        ARRAY_TO_STRING(
            ARRAY(
                SELECT DISTINCT
                    county
                FROM UNNEST(serviced_counties.operating_counties) county
                ORDER BY county
            ),
            innerDelimiter
        ) AS counties_served,
        orgs.website AS agency_website,
        county_geog.caltrans_district AS caltrans_district_id,
        county_geog.caltrans_district_name AS caltrans_district_name,
        orgs.is_public_entity AS is_public_entity,
        orgs.public_currently_operating AS is_publicly_operating,
        program_funding.funding_programs AS funding_sources,
        annual_ntd.voms_do AS on_demand_vehicles_at_max_service,
        annual_ntd.total_voms AS vehicles_at_max_service,
        ARRAY_TO_STRING(
            ARRAY(
                SELECT DISTINCT
                    uris
                FROM UNNEST(gtfs_data.gtfs_uris) uris
                ORDER BY uris
            ),
            innerDelimiter
        ) AS gtfs_schedule_uris
    FROM
        mart_transit_database.dim_organizations orgs
    LEFT JOIN
        mart_transit_database.bridge_organizations_x_headquarters_county_geography orgs_x_hq ON orgs.key = orgs_x_hq.organization_key
    LEFT JOIN
        mart_transit_database.dim_county_geography county_geog ON orgs_x_hq.county_geography_key = county_geog.key
    LEFT JOIN
        program_funding ON program_funding.organization_key = orgs.key
    LEFT JOIN
        annual_ntd ON annual_ntd.ntd_id = orgs.ntd_id
    LEFT JOIN
        gtfs_data ON gtfs_data.key = orgs.key
    LEFT JOIN
        serviced_counties ON serviced_counties.key = orgs.key
    WHERE
        orgs._is_current IS TRUE AND
        public_currently_operating IS TRUE
)

SELECT * FROM dim_mobility_mart_providers
