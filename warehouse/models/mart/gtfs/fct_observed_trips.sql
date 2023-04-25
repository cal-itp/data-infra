{{
    config(
        materialized='table',
    )
}}

WITH

urls_to_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),
assessment_entities AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),
trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_summaries') }}
),
vehicle_positions AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),
service_alerts AS (
    SELECT * FROM {{ ref('fct_service_alerts_trip_summaries') }}
),

-- get each of these distinct
trip_updates_to_schedule AS (
    SELECT DISTINCT
        date,
        gtfs_dataset_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
    FROM assessment_entities
    WHERE gtfs_dataset_type = 'trip_updates'
),
vehicle_positions_to_schedule AS (
    SELECT DISTINCT
        date,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        gtfs_dataset_key,
    FROM assessment_entities
    WHERE gtfs_dataset_type = 'vehicle_positions'
),
service_alerts_to_schedule AS (
    SELECT DISTINCT
        date,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        gtfs_dataset_key,
    FROM assessment_entities
    WHERE gtfs_dataset_type = 'service_alerts'
),


-- Per usual, see https://gtfs.org/realtime/reference/#message-tripdescriptor for what uniquely
-- identifies a trip in a given feed. Computing this ahead of time simplifies the join conditions
-- since we want to treat "nulls" as joinable.
trip_updates_with_associated_schedule AS (
    SELECT
        trip_updates.*,
        {{ dbt_utils.generate_surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        urls_to_datasets.gtfs_dataset_key,
        trip_updates_to_schedule.schedule_to_use_for_rt_validation_gtfs_dataset_key,
    FROM trip_updates
    LEFT JOIN urls_to_datasets
        ON trip_updates.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(trip_updates.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN trip_updates_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = trip_updates_to_schedule.gtfs_dataset_key
        AND trip_updates.dt = trip_updates_to_schedule.date
),
vehicle_positions_with_associated_schedule AS (
    SELECT
        vehicle_positions.*,
        {{ dbt_utils.generate_surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        urls_to_datasets.gtfs_dataset_key,
        vehicle_positions_to_schedule.schedule_to_use_for_rt_validation_gtfs_dataset_key,
    FROM vehicle_positions
    LEFT JOIN urls_to_datasets
        ON vehicle_positions.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(vehicle_positions.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN vehicle_positions_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = vehicle_positions_to_schedule.gtfs_dataset_key
        AND vehicle_positions.dt = vehicle_positions_to_schedule.date
),
service_alerts_with_associated_schedule AS (
    SELECT
        service_alerts.*,
        {{ dbt_utils.generate_surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        urls_to_datasets.gtfs_dataset_key,
        service_alerts_to_schedule.schedule_to_use_for_rt_validation_gtfs_dataset_key,
    FROM service_alerts
    LEFT JOIN urls_to_datasets
        ON service_alerts.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(service_alerts.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN service_alerts_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = service_alerts_to_schedule.gtfs_dataset_key
        AND service_alerts.dt = service_alerts_to_schedule.date
),

fct_observed_trips AS (
    SELECT
        -- keys/identifiers
        {{ dbt_utils.generate_surrogate_key([
            'dt',
            'schedule_to_use_for_rt_validation_gtfs_dataset_key',
            'trip_identifier',
        ]) }} as key,
        dt,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        trip_identifier,
        COALESCE(tu.trip_id, vp.trip_id, sa.trip_id) AS trip_id,
        COALESCE(tu.trip_route_id, vp.trip_route_id, sa.trip_route_id) AS trip_route_id,
        COALESCE(tu.trip_direction_id, vp.trip_direction_id, sa.trip_direction_id) AS trip_direction_id,
        COALESCE(tu.trip_start_time, vp.trip_start_time, sa.trip_start_time) AS trip_start_time,
        COALESCE(tu.trip_start_date, vp.trip_start_date, sa.trip_start_date) AS trip_start_date,

        -- foreign keys
        tu.gtfs_dataset_key AS tu_gtfs_dataset_key,
        tu.base64_url AS tu_base64_url,
        vp.gtfs_dataset_key AS vp_gtfs_dataset_key,
        vp.base64_url AS vp_base64_url,
        sa.gtfs_dataset_key AS sa_gtfs_dataset_key,
        sa.base64_url AS sa_base64_url,

        -- trip updates facts
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_extract_ts AS tu_min_extract_ts,
        tu.max_extract_ts AS tu_max_extract_ts,
        tu.min_header_timestamp AS tu_min_header_timestamp,
        tu.max_header_timestamp AS tu_max_header_timestamp,
        tu.min_trip_update_timestamp AS tu_min_trip_update_timestamp,
        tu.max_trip_update_timestamp AS tu_max_trip_update_timestamp,
        tu.max_delay AS tu_max_delay,
        tu.num_skipped_stops AS tu_num_skipped_stops,
        tu.num_scheduled_canceled_added_stops AS tu_num_scheduled_canceled_added_stops,

        -- vehicle positions facts
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_extract_ts AS vp_min_extract_ts,
        vp.max_extract_ts AS vp_max_extract_ts,
        vp.min_header_timestamp AS vp_min_header_timestamp,
        vp.max_header_timestamp AS vp_max_header_timestamp,
        vp.min_vehicle_timestamp AS vp_min_vehicle_timestamp,
        vp.max_vehicle_timestamp AS vp_max_vehicle_timestamp,
        vp.first_position_latitude AS vp_first_position_latitude,
        vp.first_position_longitude AS vp_first_position_longitude,
        vp.last_position_latitude AS vp_last_position_latitude,
        vp.last_position_longitude AS vp_last_position_longitude,

        -- service alerts facts
        sa.num_distinct_message_ids AS sa_num_distinct_message_ids,
        sa.service_alert_message_keys AS sa_service_alert_message_keys,
        sa.min_extract_ts AS sa_min_extract_ts,
        sa.max_extract_ts AS sa_max_extract_ts,
        sa.min_header_timestamp AS sa_min_header_timestamp,
        sa.max_header_timestamp AS sa_max_header_timestamp,

    FROM trip_updates_with_associated_schedule AS tu
    FULL OUTER JOIN vehicle_positions_with_associated_schedule AS vp
        USING (dt, schedule_to_use_for_rt_validation_gtfs_dataset_key, trip_identifier)
    FULL OUTER JOIN service_alerts_with_associated_schedule AS sa
        USING (dt, schedule_to_use_for_rt_validation_gtfs_dataset_key, trip_identifier)
    WHERE schedule_to_use_for_rt_validation_gtfs_dataset_key IS NOT NULL
        AND trip_identifier != 'baea044d32c787353f49b168a215e098' -- the hash of all-null trip identifier fields
)

SELECT * FROM fct_observed_trips
