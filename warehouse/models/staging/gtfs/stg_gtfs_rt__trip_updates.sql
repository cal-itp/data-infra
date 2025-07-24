{{ config(materialized='table') }}

WITH stg_gtfs_rt__trip_updates AS (
    SELECT
        dt,
        hour,
        base64_url,

        metadata.extract_ts AS _extract_ts,
        metadata.extract_config.extracted_at AS _config_extract_ts,
        metadata.extract_config.name AS _name,

        TIMESTAMP_SECONDS(header.timestamp) AS header_timestamp,
        header.incrementality AS header_incrementality,
        header.gtfsRealtimeVersion AS header_version,

        id,

        TIMESTAMP_SECONDS(tripUpdate.timestamp) AS trip_update_timestamp,
        tripUpdate.delay as trip_update_delay,

        tripUpdate.vehicle.id AS vehicle_id,
        tripUpdate.vehicle.label AS vehicle_label,
        tripUpdate.vehicle.licensePlate AS vehicle_license_plate,
        tripUpdate.vehicle.wheelchairAccessible AS vehicle_wheelchair_accessible,

        tripUpdate.trip.tripId AS trip_id,
        tripUpdate.trip.routeId AS trip_route_id,
        tripUpdate.trip.directionId AS trip_direction_id,
        tripUpdate.trip.startTime AS trip_start_time,
        {{ gtfs_time_string_to_interval('tripUpdate.trip.startTime') }} AS trip_start_time_interval,
        PARSE_DATE("%Y%m%d", tripUpdate.trip.startDate) AS trip_start_date,
        tripUpdate.trip.scheduleRelationship AS trip_schedule_relationship,

        tripUpdate.stopTimeUpdate AS stop_time_updates,

    FROM {{ source('external_gtfs_rt', 'trip_updates') }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) -- last 6 months
)

SELECT * FROM stg_gtfs_rt__trip_updates
