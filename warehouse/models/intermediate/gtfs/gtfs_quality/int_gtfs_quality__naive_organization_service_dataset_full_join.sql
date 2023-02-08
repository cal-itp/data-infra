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

ntd_bridge AS (
    SELECT *
    FROM date_spine
    LEFT JOIN {{ ref('bridge_organizations_x_ntd_agency_info') }} AS dim
    ON CAST(date_spine.date AS TIMESTAMP) BETWEEN dim._valid_from AND dim._valid_to
),

feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feeds') }}
    -- this table goes into the future
    WHERE date < CURRENT_DATE()
),

int_gtfs_quality__naive_organization_service_dataset_full_join AS (
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
        orgs.itp_id AS organization_itp_id,
        orgs.source_record_id AS organization_source_record_id,
        orgs.hubspot_company_record_id AS organization_hubspot_company_record_id,
        ntd_bridge.ntd_id AS organization_ntd_id,
        COALESCE(
            orgs.assessment_status,
            (orgs.reporting_category = "Core") OR (orgs.reporting_category = "Other Public Transit"),
            FALSE
        ) AS organization_assessed,
        services.name AS service_name,
        services.assessment_status AS services_raw_assessment_status,
        services.currently_operating AS service_currently_operating,
        services.source_record_id AS service_source_record_id,
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
        service_data.agency_id,
        service_data.route_id,
        service_data.network_id,
        service_data.source_record_id AS gtfs_service_data_source_record_id,
        datasets.name AS gtfs_dataset_name,
        datasets.type AS gtfs_dataset_type,
        datasets.regional_feed_type,
        datasets.source_record_id AS gtfs_dataset_source_record_id,
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
    LEFT JOIN validation_bridge
        ON datasets.date = validation_bridge.date
        AND datasets.key = validation_bridge.gtfs_dataset_key
    FULL OUTER JOIN feeds
        ON datasets.date = feeds.date
        AND datasets.base64_url = feeds.base64_url
    LEFT JOIN ntd_bridge
        ON orgs.key = ntd_bridge.organization_key
        AND orgs.date = ntd_bridge.date
)

SELECT * FROM int_gtfs_quality__naive_organization_service_dataset_full_join
