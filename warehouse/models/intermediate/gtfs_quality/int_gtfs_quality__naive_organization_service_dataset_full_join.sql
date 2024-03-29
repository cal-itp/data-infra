{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT date_day AS date
    FROM {{ ref('util_transit_database_history_date_spine') }}
),

orgs AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('dim_organizations') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

services AS (
    SELECT
        date_spine.date,
        dim.*,
        ARRAY_TO_STRING(service_type, ',') AS service_type_str
    FROM date_spine
    LEFT JOIN {{ ref('dim_services') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

service_data AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('dim_gtfs_service_data') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

datasets AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('dim_gtfs_datasets') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

org_service_bridge AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('bridge_organizations_x_services_managed') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

validation_bridge AS (
    SELECT
        date_spine.date,
        dim.*
    FROM date_spine
    LEFT JOIN {{ ref('bridge_schedule_dataset_for_validation') }} AS dim
        ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

-- for history before Airtable, there are URLs that we were attempting to download
schedule_urls AS (
    SELECT DISTINCT
        EXTRACT(DATE FROM ts) AS date,
        base64_url,
         "schedule" AS feed_type
    FROM {{ ref('fct_schedule_feed_downloads') }}
    -- just to be safe
    WHERE EXTRACT(DATE FROM ts) < CURRENT_DATE()
),

schedule_feeds AS (
    SELECT *, "schedule" AS feed_type
    FROM {{ ref('fct_daily_schedule_feeds') }}
    -- this table goes into the future
    WHERE date < CURRENT_DATE()
),

rt_feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_feed_files') }}
    WHERE date < CURRENT_DATE()
),

int_gtfs_quality__naive_organization_service_dataset_full_join AS (
    SELECT
        COALESCE(orgs.date,
            services.date,
            service_data.date,
            datasets.date,
            schedule_urls.date,
            schedule_feeds.date,
            rt_feeds.date) AS date,
        orgs.key AS organization_key,
        COALESCE(services.key,
            service_data.service_key)
            AS service_key,
        COALESCE(service_data.gtfs_dataset_key,
            datasets.key) AS gtfs_dataset_key,
        orgs.name AS organization_name,
        orgs._deprecated__assessment_status AS _deprecated__organization_raw_assessment_status,
        orgs.is_public_entity AS organization_is_public_entity,
        orgs.public_currently_operating AS organization_public_currently_operating,
        orgs.public_currently_operating_fixed_route AS organization_public_currently_operating_fixed_route,
        orgs.reporting_category AS reporting_category,
        orgs.itp_id AS organization_itp_id,
        orgs.source_record_id AS organization_source_record_id,
        orgs.hubspot_company_record_id AS organization_hubspot_company_record_id,
        orgs.ntd_id AS organization_ntd_id,
        services.name AS service_name,
        services._deprecated__assessment_status AS _deprecated__services_raw_assessment_status,
        services._deprecated__currently_operating AS _deprecated__service_currently_operating,
        services.operational_status AS service_operational_status,
        services.start_date AS service_start_date,
        services.deprecated_date AS service_deprecated_date,
        services.public_currently_operating AS service_public_currently_operating,
        services.public_currently_operating_fixed_route AS service_public_currently_operating_fixed_route,
        services.fixed_route AS service_fixed_route,
        services.is_public AS service_is_public,
        services.source_record_id AS service_source_record_id,
        service_type_str,

        service_data.key AS gtfs_service_data_key,
        service_data.customer_facing AS gtfs_service_data_customer_facing,
        service_data.category AS gtfs_service_data_category,

        service_data.source_record_id AS gtfs_service_data_source_record_id,
        datasets.name AS gtfs_dataset_name,
        COALESCE(datasets.type, rt_feeds.feed_type, schedule_feeds.feed_type, schedule_urls.feed_type) AS gtfs_dataset_type,
        datasets.regional_feed_type,
        datasets.backdated_regional_feed_type,
        datasets.source_record_id AS gtfs_dataset_source_record_id,
        datasets.deprecated_date AS gtfs_dataset_deprecated_date,
        validation_bridge.schedule_to_use_for_rt_validation_gtfs_dataset_key,
        COALESCE(datasets.base64_url, schedule_urls.base64_url, schedule_feeds.base64_url, rt_feeds.base64_url) AS base64_url,
        schedule_feeds.feed_key AS schedule_feed_key,
        rt_feeds.key IS NOT NULL AS had_rt_files
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
    LEFT JOIN validation_bridge
        ON datasets.date = validation_bridge.date
        AND datasets.key = validation_bridge.gtfs_dataset_key
    FULL OUTER JOIN schedule_urls
        ON datasets.date = schedule_urls.date
        AND datasets.base64_url = schedule_urls.base64_url
    FULL OUTER JOIN schedule_feeds
        ON COALESCE(datasets.date, schedule_urls.date) = schedule_feeds.date
        AND COALESCE(datasets.base64_url, schedule_urls.base64_url) = schedule_feeds.base64_url
    FULL OUTER JOIN rt_feeds
        ON datasets.date = rt_feeds.date
        AND datasets.base64_url = rt_feeds.base64_url
    -- just to be on the safe side, double check that we aren't including current date
    WHERE COALESCE(orgs.date,
            services.date,
            service_data.date,
            datasets.date,
            schedule_urls.date,
            schedule_feeds.date,
            rt_feeds.date) < CURRENT_DATE()
)

SELECT * FROM int_gtfs_quality__naive_organization_service_dataset_full_join
