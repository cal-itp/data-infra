{{ config(materialized='table') }}

WITH assessed_orgs AS (
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


full_join AS (
    SELECT
        COALESCE(orgs.date, services.date,) AS date
        orgs.key AS organization_key,
        orgs.name AS organization_name,
        orgs.assessment_status AS organization_raw_assessment_status,
        orgs.reporting_category AS orgs.reporting_category,
        services.key AS service_key,
        services.name AS service_name,
        services.assessment_status AS services_raw_assessment_status,
        services.currently_operating AS service_currently_operating,
        service_type,
        gtfs_service_data_key,
        gtfs_service_data.customer_facing AS gtfs_service_data_customer_facing,
        gtfs_service_data.category AS gtfs_service_data_category,

    FROM orgs
    FULL OUTER JOIN services
        ON orgs.date = services.date
        AND orgs.mobility_services_managed = services.key
        AND orgs.key = services.provider
    FULL OUTER JOIN gtfs_service_data
        ON services.date = gtfs_service_data.date
        AND services.key = gtfs_service_data.service_key



)
