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
        orgs.itp_id AS organization_itp_id,
        orgs.original_record_id AS organization_original_record_id,
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
        services.original_record_id AS service_original_record_id,
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
        service_data.original_record_id AS gtfs_service_data_original_record_id,
        datasets.name AS gtfs_dataset_name,
        datasets.type AS gtfs_dataset_type,
        datasets.regional_feed_type,
        datasets.original_record_id AS gtfs_dataset_original_record_id,
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
),

initial_assessed AS (
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

        organization_original_record_id,
        service_original_record_id,
        gtfs_service_data_original_record_id,
        gtfs_dataset_original_record_id,

        (organization_assessed
            AND service_assessed
            AND gtfs_service_data_assessed) AS assessed,

        organization_assessed,

        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,
        service_assessed,
        gtfs_service_data_assessed,
        gtfs_service_data_customer_facing,
        regional_feed_type,

        agency_id,
        route_id,
        network_id,

        base64_url,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key
    FROM full_join
),

check_regional_feed_types AS (
    SELECT
        date,
        organization_key,
        service_key,
        -- use subfeed only if this org/service pair:
        --  has both feed types
        --  one of those feed types is assessed for the pair
        ('Regional Subfeed' IN UNNEST(ARRAY_AGG(regional_feed_type))
            AND 'Combined Regional Feed' IN UNNEST(ARRAY_AGG(regional_feed_type)))
        AND LOGICAL_OR(assessed) AS use_subfeed_for_reports
    FROM initial_assessed
    WHERE regional_feed_type IN ('Regional Subfeed', 'Combined Regional Feed')
    GROUP BY date, organization_key, service_key
),

int_gtfs_quality__daily_assessment_candidate_entities AS (
    SELECT
        key,
        date,
        organization_name,
        service_name,
        gtfs_dataset_name,
        gtfs_dataset_type,

        organization_original_record_id,
        service_original_record_id,
        gtfs_service_data_original_record_id,
        gtfs_dataset_original_record_id,

        assessed AS guidelines_assessed,
        CASE
            WHEN (check_regional_feed_types.use_subfeed_for_reports
                AND regional_feed_type = 'Combined Regional Feed') THEN FALSE
            WHEN (check_regional_feed_types.use_subfeed_for_reports
                AND regional_feed_type = 'Regional Subfeed') THEN TRUE
            ELSE assessed
        END AS reports_site_assessed,
        organization_assessed,
        service_assessed,
        gtfs_service_data_assessed,
        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,
        gtfs_service_data_customer_facing,
        regional_feed_type,
        check_regional_feed_types.use_subfeed_for_reports,
        agency_id,
        route_id,
        network_id,
        base64_url,
        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key
    FROM initial_assessed
    LEFT JOIN check_regional_feed_types
        USING (date, organization_key, service_key)
)

SELECT * FROM int_gtfs_quality__daily_assessment_candidate_entities
