{{ config(materialized='table') }}

WITH orgs AS (
    SELECT
        hist.date,
        dim.*
    FROM {{ ref('int_transit_database__organizations_daily_history') }} AS hist
    LEFT JOIN {{ ref('dim_organizations') }} AS dim
        ON hist.organization_key = dim.key
),

services AS (
    SELECT
        hist.date,
        dim.*,
        ARRAY_TO_STRING(service_type, ',') AS service_type_str
    FROM {{ ref('int_transit_database__services_daily_history') }} AS hist
    LEFT JOIN {{ ref('dim_services') }} AS dim
        ON hist.service_key = dim.key
),

service_data AS (
    SELECT
        hist.date,
        dim.*
    FROM {{ ref('int_transit_database__gtfs_service_data_daily_history') }} AS hist
    LEFT JOIN {{ ref('dim_gtfs_service_data') }} AS dim
        ON hist.gtfs_service_data_key = dim.key
),

datasets AS (
    SELECT
        hist.date,
        dim.*
    FROM {{ ref('int_transit_database__gtfs_datasets_daily_history') }} AS hist
    LEFT JOIN {{ ref('dim_gtfs_datasets') }} AS dim
        ON hist.gtfs_dataset_key = dim.key
),

org_service_bridge AS (
    SELECT
        hist.date,
        dim.*
    FROM {{ ref('int_transit_database__bridge_organizations_x_services_managed_daily_history') }} AS hist
    LEFT JOIN {{ ref('bridge_organizations_x_services_managed') }} AS dim
        ON hist.organization_key = dim.organization_key
        AND hist.service_key = dim.service_key
),

validation_bridge AS (
    SELECT
        hist.date,
        dim.*
    FROM {{ ref('int_transit_database__bridge_schedule_dataset_for_validation_daily_history') }} AS hist
    LEFT JOIN {{ ref('bridge_schedule_dataset_for_validation') }} AS dim
        ON hist.gtfs_dataset_key = dim.gtfs_dataset_key
        AND hist.schedule_to_use_for_rt_validation_gtfs_dataset_key = dim.schedule_to_use_for_rt_validation_gtfs_dataset_key
),

feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feeds') }}
    -- this table goes into the future
    WHERE date < CURRENT_DATE()
),

full_join AS (
    SELECT
        COALESCE(orgs.date,
            services.date,
            service_data.date,
            datasets.date,
            feeds.date) AS date,
        orgs.key AS organization_key,
        COALESCE(services.key,
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

        service_data.key AS gtfs_service_data_key,
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
        validation_bridge.schedule_to_use_for_rt_validation_gtfs_dataset_key,
        COALESCE(datasets.base64_url, feeds.base64_url) AS base64_url,
        feeds.feed_key AS schedule_feed_key
    FROM orgs
    FULL OUTER JOIN org_service_bridge
        ON orgs.date = org_service_bridge.date
        AND orgs.key = org_service_bridge.organization_key
    FULL OUTER JOIN services
        ON orgs.date = services.date
        AND org_service_bridge.service_key = services.key
    FULL OUTER JOIN service_data
        ON services.date = service_data.date
        AND services.key = service_data.service_key
    FULL OUTER JOIN datasets
        ON service_data.date = datasets.date
        AND service_data.gtfs_dataset_key = datasets.key
    FULL OUTER JOIN validation_bridge
        ON datasets.date = validation_bridge.date
        AND datasets.key = validation_bridge.gtfs_dataset_key
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
        gtfs_service_data_customer_facing,
        regional_feed_type,

        base64_url,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key
    FROM full_join
)

SELECT * FROM int_gtfs_quality__daily_assessment_candidate_entities
