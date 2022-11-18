{{ config(materialized='table') }}

WITH dim_gtfs_service_data AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

dim_services AS (
    SELECT *
    FROM {{ ref('dim_services') }}
),

bridge_organizations_x_services_managed AS (
    SELECT *
    FROM {{ ref('bridge_organizations_x_services_managed') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
),

datasets_services_joined AS (
    SELECT
        service_key,
        gtfs_dataset_key,
        CASE
            WHEN data = "GTFS Schedule" THEN dim_gtfs_datasets.key
            ELSE dim_gtfs_datasets.schedule_to_use_for_rt_validation_gtfs_dataset_key
        END AS associated_gtfs_schedule_gtfs_dataset_key,
        category,
        dim_gtfs_datasets.name AS dataset_name,
        CASE
            WHEN data = 'GTFS Schedule' THEN 'schedule'
            WHEN data = 'GTFS Alerts' THEN 'service_alerts'
            WHEN data = 'GTFS TripUpdates' THEN 'trip_updates'
            WHEN data = 'GTFS VehiclePositions' THEN 'vehicle_positions'
        END AS type
    FROM dim_gtfs_service_data
    LEFT JOIN dim_gtfs_datasets
        ON dim_gtfs_service_data.gtfs_dataset_key = dim_gtfs_datasets.key
),

dedupe_torrance AS (
    SELECT
        service_key,
        gtfs_dataset_key,
        category,
        type,
        associated_gtfs_schedule_gtfs_dataset_key,
        RANK() OVER(
            PARTITION BY associated_gtfs_schedule_gtfs_dataset_key, type
            ORDER BY dataset_name) AS rnk
    FROM datasets_services_joined
),

quartet_pivoted AS (
    SELECT *
    FROM dedupe_torrance
    PIVOT(
        STRING_AGG(gtfs_dataset_key) AS gtfs_dataset_key
        FOR type IN ('schedule', 'service_alerts', 'trip_updates', 'vehicle_positions')
    )
),

quartet_labeled AS (
    SELECT
        quartet_pivoted.service_key,
        service.name AS service_name,
        organizations.name AS organization_name,
        organizations.itp_id AS itp_id,
        category,
        gtfs_dataset_key_schedule AS schedule_gtfs_dataset_key,
        schedule.name AS schedule_name,
        schedule.base64_url AS schedule_base64_url,
        gtfs_dataset_key_service_alerts AS service_alerts_gtfs_dataset_key,
        service_alerts.name AS service_alerts_name,
        service_alerts.base64_url AS service_alerts_base64_url,
        gtfs_dataset_key_vehicle_positions AS vehicle_positions_gtfs_dataset_key,
        vehicle_positions.name AS vehicle_positions_name,
        vehicle_positions.base64_url AS vehicle_positions_base64_url,
        gtfs_dataset_key_trip_updates AS trip_updates_gtfs_dataset_key,
        trip_updates.name AS trip_updates_name,
        trip_updates.base64_url AS trip_updates_base64_url,
    FROM quartet_pivoted
    LEFT JOIN dim_services AS service
        ON quartet_pivoted.service_key = service.key
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

)

SELECT * FROM quartet_labeled
