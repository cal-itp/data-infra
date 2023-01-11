{{ config(materialized='table') }}

WITH dim_gtfs_service_data AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

bridge_schedule_dataset_for_validation AS (
    SELECT *
    FROM {{ ref('bridge_schedule_dataset_for_validation') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

datasets_services_joined AS (
    SELECT
        service_key,
        dim_gtfs_service_data.gtfs_dataset_key,
        -- TODO: this logic will fail if we want to use MTC 511 regional alerts feed with
        -- all subfeeds because the subfeeds are not listed to be used for validation of the alerts feed
        -- easiest fix (very manual) is probably just to join the alerts feed in later after the quartets are constructed
        CASE
            WHEN type = "schedule" THEN dim_gtfs_datasets.key
            ELSE sched_ref.schedule_to_use_for_rt_validation_gtfs_dataset_key
        END AS associated_gtfs_schedule_gtfs_dataset_key,
        customer_facing,
        type
    FROM dim_gtfs_service_data
    LEFT JOIN dim_gtfs_datasets
        ON dim_gtfs_service_data.gtfs_dataset_key = dim_gtfs_datasets.key
    LEFT JOIN bridge_schedule_dataset_for_validation AS sched_ref
        ON dim_gtfs_datasets.key = sched_ref.gtfs_dataset_key
),

pivoted AS (
    SELECT *
    FROM datasets_services_joined
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
        pivoted.gtfs_dataset_key_vehicle_positions,
        -- pivoted._is_current,
        -- pivoted._valid_from,
        -- pivoted._valid_to
    FROM pivoted
    LEFT JOIN dim_gtfs_service_data
        ON pivoted.associated_gtfs_schedule_gtfs_dataset_key = dim_gtfs_service_data.gtfs_dataset_key
            AND pivoted.service_key = dim_gtfs_service_data.service_key
)

SELECT * FROM int_transit_database__service_datasets_pivoted
