{{ config(materialized='table') }}

WITH orgs AS (
    SELECT *
    FROM {{ ref('int_transit_database__organizations_daily_history') }}
),

services AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_daily_history') }}
),

service_data AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__gtfs_service_data_daily_history') }}
),

datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_daily_history') }}
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
            (orgs.reporting_category = "Core") OR (orgs.reporting_category = "Other Public Transit"),
            FALSE
        ) AS organization_assessed,

        services.name AS service_name,
        services.assessment_status AS services_raw_assessment_status,
        services.currently_operating AS service_currently_operating,
        service_type_str,
        COALESCE(
            services.assessment_status,
            services.currently_operating
                AND CONTAINS_SUBSTR(services.service_type_str, "fixed-route"),
            FALSE
        ) AS service_assessed,

        gtfs_service_data_key,
        service_data.customer_facing AS gtfs_service_data_customer_facing,
        service_data.category AS gtfs_service_data_category,
        COALESCE(
            service_data.customer_facing,
            service_data.category = "primary",
            FALSE
        ) AS gtfs_service_data_assessed,

        datasets.name AS gtfs_dataset_name,
        datasets.type AS gtfs_dataset_type,
        datasets.regional_feed_type,
        datasets.base64_url,

        feeds.feed_key AS schedule_feed_key
    FROM orgs
    FULL OUTER JOIN services
        ON orgs.date = services.date
        AND orgs.mobility_services_managed_service_key = services.service_key
        AND orgs.organization_key = services.provider_organization_key
    FULL OUTER JOIN service_data
        ON services.date = service_data.date
        AND services.service_key = service_data.service_key
    FULL OUTER JOIN datasets
        ON service_data.date = datasets.date
        AND service_data.gtfs_dataset_key = datasets.key
    FULL OUTER JOIN feeds
        ON datasets.date = feeds.date
        AND datasets.base64_url = feeds.base64_url
),

int_gtfs_quality__daily_assessment_candidate_entities AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'gtfs_service_data_key',
            'gtfs_dataset_key',
            'schedule_feed_key']) }} AS key,
        date,
        organization_name,
        service_name,
        gtfs_dataset_name,
        gtfs_dataset_type,

        (organization_assessed
            AND service_assessed
            AND gtfs_service_data_assessed) AS assessed,


        organization_assessed,
        service_assessed,
        gtfs_service_data_assessed,

        base64_url,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key
    FROM full_join
)

SELECT * FROM int_gtfs_quality__daily_assessment_candidate_entities
