{{ config(materialized='table') }}

WITH dim_organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

bridge_organizations_x_services_managed AS (
    SELECT * FROM {{ ref('bridge_organizations_x_services_managed') }}
),

dim_gtfs_service_data AS (
    SELECT * FROM {{ ref('dim_gtfs_service_data') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

dim_provider_service_gtfs_without_key AS (
    SELECT
        o.key AS organization_key,
        osm.service_key,
        gsd.key AS gtfs_service_data_key,
        gsd.gtfs_dataset_key,
        o.name AS organization_name,
        osm.service_name AS mobility_service,
        gsd.agency_id,
        gsd.network_id,
        gsd.route_id,
        gsd.category,
        gd.data AS dataset_type,
        gd.name AS gtfs_dataset_name,
        o.calitp_extracted_at
    FROM dim_organizations AS o
    LEFT JOIN bridge_organizations_x_services_managed AS osm
        ON o.key = osm.organization_key
        AND o.calitp_extracted_at = osm.calitp_extracted_at
    LEFT JOIN dim_gtfs_service_data AS gsd
        ON osm.service_key = gsd.service_key
        AND osm.calitp_extracted_at = gsd.calitp_extracted_at
    LEFT JOIN dim_gtfs_datasets AS gd
        ON gsd.gtfs_dataset_key = gd.key
        AND gsd.calitp_extracted_at = gd.calitp_extracted_at
    WHERE gsd.category = "primary"
),

dim_provider_service_gtfs AS (
    SELECT
        {{ farm_surrogate_key(['organization_key', 'service_key', 'gtfs_service_data_key', 'gtfs_dataset_key']) }} AS key,
        organization_name,
        mobility_service,
        agency_id,
        network_id,
        route_id,
        category,
        dataset_type,
        gtfs_dataset_name,
        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        calitp_extracted_at
    FROM dim_provider_service_gtfs_without_key
)

SELECT * FROM dim_provider_service_gtfs
