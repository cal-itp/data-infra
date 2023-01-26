{{
    config(
        materialized='table',
    )
}}

WITH

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
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
--
-- -- in RT world can use associated_schedule_gtfs_dataset_key to identify "groups" of RT feeds
-- url_to_associated_schedule_key AS (
--     SELECT
--         ff.date,
--         ff.gtfs_dataset_key,
--         pgd.associated_schedule_gtfs_dataset_key
--     FROM fct_daily_rt_feed_files AS ff
--     LEFT JOIN dim_provider_gtfs_data AS pgd
--         ON ff.date BETWEEN pgd._valid_from AND pgd._valid_to
--         AND ff.schedule_to_use_for_rt_validation_gtfs_dataset_key = pgd.associated_schedule_gtfs_dataset_key
-- ),

-- Per usual, see https://gtfs.org/realtime/reference/#message-tripdescriptor for what uniquely
-- identifies a trip in a given feed. Computing this ahead of time simplifies the join conditions
-- since we want to treat "nulls" as joinable.
trip_updates_with_associated_schedule AS (
    SELECT
        trip_updates.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        fct_daily_rt_feed_files.schedule_to_use_for_rt_validation_gtfs_dataset_key AS associated_schedule_gtfs_dataset_key,
    FROM trip_updates
    LEFT JOIN fct_daily_rt_feed_files
        ON trip_updates.dt = fct_daily_rt_feed_files.date
        AND trip_updates.base64_url = fct_daily_rt_feed_files.base64_url
),
vehicle_positions_with_associated_schedule AS (
    SELECT
        vehicle_positions.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        fct_daily_rt_feed_files.schedule_to_use_for_rt_validation_gtfs_dataset_key AS associated_schedule_gtfs_dataset_key,
    FROM vehicle_positions
    LEFT JOIN fct_daily_rt_feed_files
        ON vehicle_positions.dt = fct_daily_rt_feed_files.date
        AND vehicle_positions.base64_url = fct_daily_rt_feed_files.base64_url
),
service_alerts_with_associated_schedule AS (
    SELECT
        service_alerts.*,
        {{ dbt_utils.surrogate_key(['trip_id', 'trip_route_id', 'trip_direction_id', 'trip_start_time', 'trip_start_date']) }} AS trip_identifier,
        fct_daily_rt_feed_files.schedule_to_use_for_rt_validation_gtfs_dataset_key AS associated_schedule_gtfs_dataset_key,
    FROM service_alerts
    LEFT JOIN fct_daily_rt_feed_files
        ON service_alerts.dt = fct_daily_rt_feed_files.date
        AND service_alerts.base64_url = fct_daily_rt_feed_files.base64_url
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
