{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['service_date', 'base64_url'],
        on_schema_change='append_new_columns'
    )
}}

WITH fct_vehicle_positions_messages AS (
    SELECT *,
        COALESCE(vehicle_timestamp, header_timestamp) AS location_timestamp
    FROM {{ ref('fct_vehicle_positions_messages') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

vp_trips AS (
    SELECT
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        trip_instance_key
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

first_keying_and_filtering AS (
    SELECT * EXCEPT (key),
        {{ dbt_utils.generate_surrogate_key(['service_date', 'base64_url', 'location_timestamp', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['service_date', 'base64_url', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS vehicle_trip_key
    FROM fct_vehicle_positions_messages
    -- drop cases where trip id is null since these cannot be joined to schedule
    -- this is something we may want to reconsider
    -- TODO: theoretically we need to eventually support route / direction / start date / start time as an alternate trip identifier
    WHERE trip_id IS NOT NULL
    -- we originally dropped the Bay Area regional feed because they don't make their vehicle identifiers unique by agency
    -- so you can end up intermingling multiple vehicles
    -- however, not clear this issue remains if we are also dropping rows with no trip
    -- since regional feed does have unique trip IDs per agency
        AND gtfs_dataset_name != 'Bay Area 511 Regional VehiclePositions'
),

deduped AS (
    SELECT *
    FROM first_keying_and_filtering
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY key
        ORDER BY position_latitude, position_longitude
    ) = 1
),

get_next AS (
    SELECT deduped.*,
        LEAD(key) OVER (PARTITION BY vehicle_trip_key ORDER BY location_timestamp) AS next_location_key,
        -- BQ errors on latitudes outside this range
        CASE
            WHEN position_latitude BETWEEN -90 AND 90 THEN ST_GEOGPOINT(position_longitude, position_latitude)
        END
        AS location
    FROM deduped
),

fct_vehicle_locations AS (
    SELECT
        key,
        gtfs_dataset_key,
        dt,
        get_next.service_date,
        hour,
        get_next.base64_url,
        _extract_ts,
        _config_extract_ts,
        gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        get_next.schedule_base64_url,
        schedule_name,
        schedule_feed_key,
        schedule_feed_timezone,
        _header_message_age,
        _vehicle_message_age,
        header_timestamp,
        header_version,
        header_incrementality,
        id,
        current_stop_sequence,
        stop_id,
        current_status,
        vehicle_timestamp,
        congestion_level,
        occupancy_status,
        occupancy_percentage,
        vehicle_id,
        vehicle_label,
        vehicle_license_plate,
        vehicle_wheelchair_accessible,
        get_next.trip_id,
        trip_route_id,
        trip_direction_id,
        get_next.trip_start_time,
        trip_start_time_interval,
        trip_start_date,
        trip_schedule_relationship,
        position_latitude,
        position_longitude,
        position_bearing,
        position_odometer,
        position_speed,
        location_timestamp,
        vehicle_trip_key,
        next_location_key,
        location,
        trip_instance_key
    FROM get_next
    LEFT JOIN vp_trips
        ON get_next.service_date = vp_trips.service_date
        AND get_next.trip_id = vp_trips.trip_id
        AND get_next.base64_url = vp_trips.base64_url
        AND get_next.schedule_base64_url = vp_trips.schedule_base64_url
        -- this is often null but we need to include it for frequency based trips
        AND COALESCE(get_next.trip_start_time, "") = COALESCE(vp_trips.trip_start_time, "")
)

SELECT * FROM fct_vehicle_locations
