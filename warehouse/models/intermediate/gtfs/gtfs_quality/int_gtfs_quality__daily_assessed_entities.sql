{{ config(materialized='table') }}

WITH orgs AS (
    SELECT *
    FROM {{ ref('int_transit_database__organizations_history') }}
),

services AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_history') }}
),

service_data AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_service_data_history') }}
),

datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_history') }}
),

feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feeds') }}
    -- this table goes into the future
    WHERE date <= CURRENT_DATE()
),

full_join AS (
    SELECT
        COALESCE(orgs.date,
            services.date,
            service_data.date,
            datasets.date,
            feeds.date) AS date,
        COALESCE(orgs.organization_key, services.provider_organization_key) AS organization_key,
        COALESCE(orgs.mobility_services_managed_service_key,
            services.service_key,
            service_data.service_key)
            AS service_key,
        COALESCE(service_data.gtfs_dataset_key,
            datasets.key) AS gtfs_dataset_key,

        orgs.name AS organization_name,
        orgs.assessment_status AS organization_raw_assessment_status,
        orgs.reporting_category AS reporting_category,
        COALESCE(
            orgs.assessment_status,
            (orgs.reporting_category = "Core") OR (orgs.reporting_category = "Other Public Transit")
        ) AS organization_assessed,

        services.name AS service_name,
        services.assessment_status AS services_raw_assessment_status,
        services.currently_operating AS service_currently_operating,
        service_type_str,
        COALESCE(
            services.assessment_status,
            services.currently_operating
                AND CONTAINS_SUBSTR(services.service_type_str, "fixed-route")
        ) AS service_assessed,

        gtfs_service_data_key,
        service_data.customer_facing AS gtfs_service_data_customer_facing,
        service_data.category AS gtfs_service_data_category,
        COALESCE(
            service_data.customer_facing,
            service_data.category = "primary"
        ) AS gtfs_service_data_assessed,

        datasets.name AS gtfs_dataset_name,
        datasets.data AS gtfs_dataset_data,
        datasets.regional_feed_type,
        datasets.base64_url,

        feeds.feed_key
    FROM orgs
    FULL OUTER JOIN services
        ON orgs.date = services.date
        AND orgs.mobility_services_managed_service_key = services.service_key
        AND orgs.organization_key = services.provider_organization_key
    FULL OUTER JOIN service_data
        ON services.date = service_data.date
        AND services.key = service_data.service_key
    FULL OUTER JOIN datasets
        ON service_data.date = datasets.date
        AND service_data.gtfs_dataset_key = datasets.key
    FULL OUTER JOIN feeds
        ON datasets.date = feeds.date
        AND datasets.base64_url = feeds.base64_url
)

SELECT * FROM full_join
