WITH source AS (
    SELECT * FROM {{ source('gtfs_rt_external_tables', 'trip_updates') }}
),

stg_rt__trip_updates AS (
    SELECT
        metadata.itp_id AS calitp_itp_id,
        metadata.url AS calitp_url_number,
        metadata.path AS original_file_path,
        dt AS date,

        id,

        tripUpdate.timestamp AS timestamp,
        tripUpdate.delay AS delay,

        tripUpdate.vehicle.id AS vehicle_id,
        tripUpdate.vehicle.label AS vehicle_label,
        tripUpdate.vehicle.licensePlate AS vehicle_license_plate,

        tripUpdate.trip.tripId AS trip_id,
        tripUpdate.trip.routeId AS trip_route_id,
        tripUpdate.trip.directionId AS trip_direction_id,
        tripUpdate.trip.startTime AS trip_start_time,
        tripUpdate.trip.startDate AS trip_start_date,
        tripUpdate.trip.scheduleRelationship AS trip_schedule_relationship,

        tripUpdate.stopTimeUpdate AS stop_time_updates,

        {{ dbt_utils.surrogate_key(['metadata.path',
                                    'id',
                                    'tripUpdate.timestamp',
                                    'tripUpdate.vehicle.id',
                                    'tripUpdate.vehicle.label',
                                    'tripUpdate.trip.tripId',
                                    'tripUpdate.trip.startTime',
                                    'tripUpdate.trip.startDate']) }} AS key

    FROM source

    WHERE tripUpdate.vehicle.id IS NOT NULL
)

SELECT * FROM stg_rt__trip_updates
