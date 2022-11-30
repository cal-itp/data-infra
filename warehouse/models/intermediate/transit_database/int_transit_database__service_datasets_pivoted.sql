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
        -- TODO: this logic will fail if we want to use MTC 511 regional alerts feed with
        -- all subfeeds because the subfeeds are not listed to be used for validation of the alerts feed
        -- easiest fix (very manual) is probably just to join the alerts feed in later after the quartets are constructed
        CASE
            WHEN data = "GTFS Schedule" THEN dim_gtfs_datasets.key
            ELSE dim_gtfs_datasets.schedule_to_use_for_rt_validation_gtfs_dataset_key
        END AS associated_gtfs_schedule_gtfs_dataset_key,
        category,
        customer_facing,
        agency_id,
        network_id,
        route_id,
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

-- TODO: can remove this when data entry for Torrance is corrected so that only one feed is primary
dedupe_torrance AS (
    SELECT
        service_key,
        gtfs_dataset_key,
        customer_facing,
        type,
        associated_gtfs_schedule_gtfs_dataset_key,
        RANK() OVER(
            PARTITION BY associated_gtfs_schedule_gtfs_dataset_key, type
            ORDER BY dataset_name) AS rnk
    FROM datasets_services_joined
),

pivoted AS (
    SELECT *
    FROM dedupe_torrance
    PIVOT(
        STRING_AGG(gtfs_dataset_key) AS gtfs_dataset_key
        FOR type IN ('schedule', 'service_alerts', 'trip_updates', 'vehicle_positions')
    )
),

int_transit_database__service_datasets_pivoted AS (
    SELECT
        pivoted.service_key,
        pivoted.customer_facing,
        dim_gtfs_service_data.agency_id,
        dim_gtfs_service_data.network_id,
        dim_gtfs_service_data.route_id,
        pivoted.associated_gtfs_schedule_gtfs_dataset_key,
        pivoted.gtfs_dataset_key_schedule,
        pivoted.gtfs_dataset_key_service_alerts,
        pivoted.gtfs_dataset_key_trip_updates,
        pivoted.gtfs_dataset_key_vehicle_positions
    FROM pivoted
    LEFT JOIN dim_gtfs_service_data
    ON pivoted.associated_gtfs_schedule_gtfs_dataset_key = dim_gtfs_service_data.gtfs_dataset_key
        AND pivoted.service_key = dim_gtfs_service_data.service_key
)

SELECT * FROM int_transit_database__service_datasets_pivoted
