{{ config(materialized='table') }}

WITH stg_gtfs_rt__vehicle_positions AS (
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

        vehicle.currentStopSequence AS current_stop_sequence,
        vehicle.stopId AS stop_id,
        vehicle.currentStatus AS current_status,
        TIMESTAMP_SECONDS(vehicle.timestamp) AS vehicle_timestamp,
        vehicle.congestionLevel AS congestion_level,
        vehicle.occupancyStatus AS occupancy_status,
        vehicle.occupancyPercentage AS occupancy_percentage,

        vehicle.vehicle.id AS vehicle_id,
        vehicle.vehicle.label AS vehicle_label,
        vehicle.vehicle.licensePlate AS vehicle_license_plate,
        vehicle.vehicle.wheelchairAccessible AS vehicle_wheelchair_accessible,

        vehicle.trip.tripId AS trip_id,
        vehicle.trip.routeId AS trip_route_id,
        vehicle.trip.directionId AS trip_direction_id,
        vehicle.trip.startTime AS trip_start_time,
        {{ gtfs_time_string_to_interval('vehicle.trip.startTime') }} AS trip_start_time_interval,
        PARSE_DATE("%Y%m%d", vehicle.trip.startDate) AS trip_start_date,
        vehicle.trip.scheduleRelationship AS trip_schedule_relationship,

        vehicle.position.latitude AS position_latitude,
        vehicle.position.longitude AS position_longitude,
        vehicle.position.bearing AS position_bearing,
        vehicle.position.odometer AS position_odometer,
        vehicle.position.speed AS position_speed

    FROM {{ source('external_gtfs_rt', 'vehicle_positions') }}
    WHERE dt >= '2025-07-01' -- Temporary filter
)

SELECT * FROM stg_gtfs_rt__vehicle_positions
