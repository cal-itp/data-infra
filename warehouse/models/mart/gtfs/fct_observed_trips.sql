{{
    config(
        materialized='table',
    )
}}

WITH

urls_to_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),
dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),
trip_updates AS (
    SELECT * FROM {{ ref('int_gtfs_rt__trip_updates_summaries') }}
),
vehicle_positions AS (
    SELECT * FROM {{ ref('int_gtfs_rt__vehicle_positions_trip_summaries') }}
),
service_alerts AS (
    SELECT * FROM {{ ref('int_gtfs_rt__service_alerts_trip_summaries') }}
),

-- get each of these distinct
trip_updates_to_schedule AS (
    SELECT DISTINCT
        associated_schedule_gtfs_dataset_key,
        trip_updates_gtfs_dataset_key,
        _valid_from,
        _valid_to,
    FROM dim_provider_gtfs_data
),
vehicle_positions_to_schedule AS (
    SELECT DISTINCT
        associated_schedule_gtfs_dataset_key,
        vehicle_positions_gtfs_dataset_key,
        _valid_from,
        _valid_to,
    FROM dim_provider_gtfs_data
),
service_alerts_to_schedule AS (
    SELECT DISTINCT
        associated_schedule_gtfs_dataset_key,
        service_alerts_gtfs_dataset_key,
        _valid_from,
        _valid_to,
    FROM dim_provider_gtfs_data
),


-- Per usual, see https://gtfs.org/realtime/reference/#message-tripdescriptor for what uniquely
-- identifies a trip in a given feed. Computing this ahead of time simplifies the join conditions
-- since we want to treat "nulls" as joinable.
trip_updates_with_associated_schedule AS (
    SELECT
        trip_updates.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        trip_updates_to_schedule.associated_schedule_gtfs_dataset_key,
    FROM trip_updates
    LEFT JOIN urls_to_datasets
        ON trip_updates.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(trip_updates.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN trip_updates_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = trip_updates_to_schedule.trip_updates_gtfs_dataset_key
        AND TIMESTAMP(trip_updates.dt) BETWEEN trip_updates_to_schedule._valid_from AND trip_updates_to_schedule._valid_to
),
vehicle_positions_with_associated_schedule AS (
    SELECT
        vehicle_positions.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        vehicle_positions_to_schedule.associated_schedule_gtfs_dataset_key,
    FROM vehicle_positions
    LEFT JOIN urls_to_datasets
        ON vehicle_positions.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(vehicle_positions.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN vehicle_positions_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = vehicle_positions_to_schedule.vehicle_positions_gtfs_dataset_key
        AND TIMESTAMP(vehicle_positions.dt) BETWEEN vehicle_positions_to_schedule._valid_from AND vehicle_positions_to_schedule._valid_to
),
service_alerts_with_associated_schedule AS (
    SELECT
        service_alerts.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        urls_to_datasets.gtfs_dataset_key,
        service_alerts_to_schedule.associated_schedule_gtfs_dataset_key,
    FROM service_alerts
    LEFT JOIN urls_to_datasets
        ON service_alerts.base64_url = urls_to_datasets.base64_url
        AND TIMESTAMP(service_alerts.dt) BETWEEN urls_to_datasets._valid_from AND urls_to_datasets._valid_to
    LEFT JOIN service_alerts_to_schedule
        ON urls_to_datasets.gtfs_dataset_key = service_alerts_to_schedule.service_alerts_gtfs_dataset_key
    QUALIFY ROW_NUMBER() OVER (PARTITION BY trip_identifier) = 1
        AND TIMESTAMP(service_alerts.dt) BETWEEN service_alerts_to_schedule._valid_from AND service_alerts_to_schedule._valid_to
),

fct_observed_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'dt',
            'associated_schedule_gtfs_dataset_key',
            'trip_identifier',
        ]) }} as key,
        dt,
        associated_schedule_gtfs_dataset_key,
        trip_identifier,
        COALESCE(tu.trip_id, vp.trip_id, sa.trip_id) AS trip_id,
        COALESCE(tu.trip_route_id, vp.trip_route_id, sa.trip_route_id) AS trip_route_id,
        COALESCE(tu.trip_direction_id, vp.trip_direction_id, sa.trip_direction_id) AS trip_direction_id,
        COALESCE(tu.trip_start_time, vp.trip_start_time, sa.trip_start_time) AS trip_start_time,
        COALESCE(tu.trip_start_date, vp.trip_start_date, sa.trip_start_date) AS trip_start_date,
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_trip_update_timestamp AS tu_min_trip_update_timestamp,
        tu.max_trip_update_timestamp AS tu_max_trip_update_timestamp,
        tu.max_delay AS tu_max_delay,
        tu.num_skipped_stops AS tu_num_skipped_stops,
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_trip_update_timestamp AS vp_min_trip_update_timestamp,
        vp.max_trip_update_timestamp AS vp_max_trip_update_timestamp,
        sa.num_distinct_message_ids AS sa_num_distinct_message_ids,
        sa.service_alert_message_keys AS sa_service_alert_message_keys,
    FROM trip_updates_with_associated_schedule AS tu
    FULL OUTER JOIN vehicle_positions_with_associated_schedule AS vp
        USING (dt, associated_schedule_gtfs_dataset_key, trip_identifier)
    FULL OUTER JOIN service_alerts_with_associated_schedule AS sa
        USING (dt, associated_schedule_gtfs_dataset_key, trip_identifier)
    WHERE associated_schedule_gtfs_dataset_key IS NOT NULL
        AND trip_identifier != 'baea044d32c787353f49b168a215e098' -- the hash of all-null trip identifier fields
)

SELECT * FROM fct_observed_trips
