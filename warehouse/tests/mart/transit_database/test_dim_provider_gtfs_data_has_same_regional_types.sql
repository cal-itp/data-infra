{{ config(store_failures = true) }}

-- Test that all URLs in a given "quartet" have the same
-- regional_feed_type value

WITH dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

join_regional_types AS (
    SELECT
        schedule.key,
        schedule.regional_feed_type AS sched_regional_feed_type,
        service_alerts.regional_feed_type AS sa_regional_feed_type,
        trip_updates.regional_feed_type AS tu_regional_feed_type,
        vehicle_positions.regional_feed_type AS vp_regional_feed_type,
        (
            schedule.regional_feed_type = service_alerts.regional_feed_type
            AND
            schedule.regional_feed_type = trip_updates.regional_feed_type
            AND
            schedule.regional_feed_type = vehicle_positions.regional_feed_type
        ) AS check
    FROM dim_provider_gtfs_data AS schedule
    LEFT JOIN dim_gtfs_datasets AS service_alerts
        ON schedule.service_alerts_gtfs_dataset_key = service_alerts.key
    LEFT JOIN dim_gtfs_datasets AS vehicle_positions
        ON schedule.vehicle_positions_gtfs_dataset_key = vehicle_positions.key
    LEFT JOIN dim_gtfs_datasets AS trip_updates
        ON schedule.trip_updates_gtfs_dataset_key = trip_updates.key
),

mismatched_types AS (
    SELECT
        key,
        sched_regional_feed_type,
        sa_regional_feed_type,
        tu_regional_feed_type,
        vp_regional_feed_type,
    FROM join_regional_types
    WHERE NOT check
)

SELECT * FROM mismatched_types
