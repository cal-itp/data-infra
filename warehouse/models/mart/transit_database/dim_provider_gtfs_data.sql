{{ config(materialized='table') }}

WITH dim_organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

dim_services AS (
    SELECT * FROM {{ ref('dim_services') }}
),

bridge_organizations_x_services_managed AS (
    SELECT * FROM {{ ref('bridge_organizations_x_services_managed') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

dim_ntd_agency_info AS (
    SELECT * FROM {{ ref('dim_ntd_agency_info') }}
),

quartet_pivoted AS (
    SELECT * FROM {{ ref('int_transit_database__service_datasets_pivoted') }}
),

dim_provider_service_gtfs AS (
    SELECT
        {{ farm_surrogate_key(['organizations.key',
            'quartet_pivoted.service_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_dataset_key_trip_updates']) }} AS key,
        quartet_pivoted.service_key,
        services.name AS service_name,
        organizations.key AS organization_key,
        organizations.name AS organization_name,
        organizations.itp_id AS itp_id,
        customer_facing,
        agency_id,
        network_id,
        route_id,
        ntd.ntd_id,
        hubspot_company_record_id,
        gtfs_dataset_key_schedule AS schedule_gtfs_dataset_key,
        schedule.name AS schedule_name,
        schedule.regional_feed_type AS regional_feed_type,
        gtfs_dataset_key_service_alerts AS service_alerts_gtfs_dataset_key,
        service_alerts.name AS service_alerts_name,
        gtfs_dataset_key_vehicle_positions AS vehicle_positions_gtfs_dataset_key,
        vehicle_positions.name AS vehicle_positions_name,
        gtfs_dataset_key_trip_updates AS trip_updates_gtfs_dataset_key,
        trip_updates.name AS trip_updates_name
    FROM quartet_pivoted
    LEFT JOIN dim_services AS services
        ON quartet_pivoted.service_key = services.key
    LEFT JOIN dim_gtfs_datasets AS schedule
        ON quartet_pivoted.gtfs_dataset_key_schedule = schedule.key
    LEFT JOIN dim_gtfs_datasets AS service_alerts
        ON quartet_pivoted.gtfs_dataset_key_service_alerts = service_alerts.key
    LEFT JOIN dim_gtfs_datasets AS vehicle_positions
        ON quartet_pivoted.gtfs_dataset_key_vehicle_positions = vehicle_positions.key
    LEFT JOIN dim_gtfs_datasets AS trip_updates
        ON quartet_pivoted.gtfs_dataset_key_trip_updates = trip_updates.key
    LEFT JOIN bridge_organizations_x_services_managed
        ON quartet_pivoted.service_key = bridge_organizations_x_services_managed.service_key
    LEFT JOIN dim_organizations AS organizations
        ON bridge_organizations_x_services_managed.organization_key = organizations.key
    LEFT JOIN dim_ntd_agency_info AS ntd
        ON organizations.ntd_agency_info_key = ntd.key
)

SELECT * FROM dim_provider_service_gtfs
