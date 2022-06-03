WITH source AS (
    SELECT * FROM {{ source('gtfs_rt_external_tables', 'vehicle_positions') }}
),

stg_rt__vehicle_positions AS (
    SELECT
        metadata.itp_id AS calitp_itp_id,
        metadata.url AS calitp_url_number,
        metadata.path AS original_file_path,
        dt AS date,

        id,

        vehicle.currentStopSequence AS current_stop_sequence,
        vehicle.stopId AS stop_id,
        vehicle.currentStatus AS current_status,
        vehicle.timestamp as timestamp,
        vehicle.congestionLevel AS congestion_level,
        vehicle.occupancyStatus AS occupancy_status,
        vehicle.occupancyPercentage AS occupancy_percentage,

        vehicle.vehicle.id AS vehicle_id,
        vehicle.vehicle.label AS vehicle_label,
        vehicle.vehicle.licensePlate AS vehicle_license_plate,

        vehicle.trip.tripId AS trip_id,
        vehicle.trip.routeId AS trip_route_id,
        vehicle.trip.directionId AS trip_direction_id,
        vehicle.trip.startTime AS trip_start_time,
        vehicle.trip.startDate AS trip_start_date,
        vehicle.trip.scheduleRelationship AS trip_schedule_relationship,

        vehicle.position.latitude AS latitude,
        vehicle.position.longitude AS longitude,
        vehicle.position.bearing AS bearing,
        vehicle.position.odometer AS odometer,
        vehicle.position.speed AS speed,

        {{ dbt_utils.surrogate_key(['metadata.path',
                                    'id',
                                    'vehicle.timestamp',
                                    'vehicle.vehicle.id',
                                    'vehicle.vehicle.label',
                                    'vehicle.trip.tripId']) }} AS key

    FROM source

    WHERE vehicle.vehicle.id IS NOT NULL
)

SELECT * FROM stg_rt__vehicle_positions
