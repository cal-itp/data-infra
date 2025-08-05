{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['service_date', 'schedule_base64_url'],
        on_schema_change='append_new_columns'
    )
}}

WITH trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_trip_summaries') }}
),

vehicle_positions AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

urls_to_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

rt_joins AS (
    SELECT
        trip_instance_key,
        -- calculated service date, schedule URL, trip ID, and iteration num are the components of the key used to join between feeds
        -- so for these we can coalesce across feeds
        -- for other fields values are not guaranteed to be the same! (so cannot coalesce)
        COALESCE(
            tu.service_date,
            vp.service_date
        ) AS service_date,
        COALESCE(
            tu.schedule_base64_url,
            vp.schedule_base64_url
        ) AS schedule_base64_url,
        COALESCE(
            tu.trip_id,
            vp.trip_id
        ) AS trip_id,
        COALESCE(
            tu.iteration_num,
            vp.iteration_num
        ) AS iteration_num,

        COALESCE(tu.warning_multiple_route_ids, FALSE)
            OR COALESCE(vp.warning_multiple_route_ids, FALSE)
            OR COALESCE((tu.trip_route_ids != COALESCE(vp.trip_route_ids, tu.trip_route_ids)), FALSE)
        AS warning_multiple_route_ids,

        tu.warning_multiple_direction_ids
            OR COALESCE(vp.warning_multiple_direction_ids, FALSE)
            OR COALESCE((tu.trip_direction_ids != COALESCE(vp.trip_direction_ids, tu.trip_direction_ids)), FALSE)
        AS warning_multiple_direction_ids,

        -- trip updates facts
        tu.trip_start_time AS tu_trip_start_time,
        tu.trip_start_time_interval AS tu_trip_start_time_interval,
        tu.trip_start_date AS tu_trip_start_date,
        tu.starting_schedule_relationship AS tu_starting_schedule_relationship,
        tu.ending_schedule_relationship AS tu_ending_schedule_relationship,
        tu.trip_schedule_relationships AS tu_trip_schedule_relationships,
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_ts AS tu_min_ts,
        tu.max_ts AS tu_max_ts,
        tu.min_datetime_pacific AS tu_min_datetime_pacific,
        tu.max_datetime_pacific AS tu_max_datetime_pacific,
        tu.num_distinct_extract_ts AS tu_num_distinct_extract_ts,
        tu.num_distinct_updates AS tu_num_distinct_updates,
        -- keep this for the join below to get the GTFS dataset record version in effect when trip data collection started
        tu.min_extract_ts AS tu_min_extract_ts,
        tu.trip_route_ids AS tu_trip_route_ids,
        tu.trip_direction_ids AS tu_trip_direction_ids,
        tu.max_delay AS tu_max_delay,
        tu.num_distinct_skipped_stops AS tu_num_skipped_stops,
        tu.num_distinct_canceled_stops AS tu_num_canceled_stops,
        tu.num_distinct_added_stops AS tu_num_added_stops,
        tu.num_distinct_scheduled_stops AS tu_num_scheduled_stops,
        tu.num_distinct_scheduled_stops
         + tu.num_distinct_canceled_stops
         + tu.num_distinct_added_stops AS tu_num_scheduled_canceled_added_stops,

        -- vehicle positions facts
        vp.trip_start_time AS vp_trip_start_time,
        vp.trip_start_time_interval AS vp_trip_start_time_interval,
        vp.trip_start_date AS vp_trip_start_date,
        vp.starting_schedule_relationship AS vp_starting_schedule_relationship,
        vp.ending_schedule_relationship AS vp_ending_schedule_relationship,
        vp.trip_schedule_relationships AS vp_trip_schedule_relationships,
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_ts AS vp_min_ts,
        vp.max_ts AS vp_max_ts,
        vp.min_datetime_pacific AS vp_min_datetime_pacific,
        vp.max_datetime_pacific AS vp_max_datetime_pacific,
        -- keep this for the join below to get the GTFS dataset record version in effect when trip data collection started
        vp.min_extract_ts AS vp_min_extract_ts,
        vp.num_distinct_extract_ts AS vp_num_distinct_extract_ts,
        vp.trip_route_ids AS vp_trip_route_ids,
        vp.trip_direction_ids AS vp_trip_direction_ids,
        vp.num_distinct_updates AS vp_num_distinct_updates,
        vp.first_position AS vp_first_position,
        vp.last_position AS vp_last_position,

        -- keying
        tu.base64_url AS tu_base64_url,
        vp.base64_url AS vp_base64_url,
    FROM trip_updates AS tu
    FULL OUTER JOIN vehicle_positions AS vp
        USING (trip_instance_key)

),

fct_observed_trips AS (
    SELECT
        trip_instance_key,
        service_date,
        schedule_base64_url,
        trip_id,
        iteration_num,
        tu_datasets.gtfs_dataset_name AS tu_name,
        vp_datasets.gtfs_dataset_name AS vp_name,
        schedule.gtfs_dataset_name AS schedule_name,
        tu_base64_url IS NOT NULL AS appeared_in_tu,
        vp_base64_url IS NOT NULL AS appeared_in_vp,

        warning_multiple_route_ids,
        warning_multiple_direction_ids,

        -- trip updates facts
        tu_trip_start_time,
        tu_trip_start_time_interval,
        tu_trip_start_date,
        tu_starting_schedule_relationship,
        tu_ending_schedule_relationship,
        tu_trip_schedule_relationships,
        tu_num_distinct_message_ids,
        tu_min_ts,
        tu_max_ts,
        tu_min_datetime_pacific,
        tu_max_datetime_pacific,
        tu_num_distinct_extract_ts,
        tu_num_distinct_updates,
        tu_trip_route_ids,
        tu_trip_direction_ids,
        tu_max_delay,
        tu_num_skipped_stops,
        tu_num_canceled_stops,
        tu_num_added_stops,
        tu_num_scheduled_stops,
        tu_num_scheduled_canceled_added_stops,

        -- vehicle positions facts
        vp_trip_start_time,
        vp_trip_start_time_interval,
        vp_trip_start_date,
        vp_starting_schedule_relationship,
        vp_ending_schedule_relationship,
        vp_trip_schedule_relationships,
        vp_num_distinct_message_ids,
        vp_min_ts,
        vp_max_ts,
        vp_min_datetime_pacific,
        vp_max_datetime_pacific,
        vp_num_distinct_updates,
        vp_num_distinct_extract_ts,
        vp_trip_route_ids,
        vp_trip_direction_ids,
        vp_first_position,
        vp_last_position,

        -- keying
        tu_base64_url,
        vp_base64_url,
        tu_datasets.gtfs_dataset_key AS tu_gtfs_dataset_key,
        vp_datasets.gtfs_dataset_key AS vp_gtfs_dataset_key,
        schedule.gtfs_dataset_key AS schedule_gtfs_dataset_key
    FROM rt_joins
    LEFT JOIN urls_to_datasets AS tu_datasets
        ON rt_joins.tu_base64_url = tu_datasets.base64_url
        AND rt_joins.tu_min_extract_ts BETWEEN tu_datasets._valid_from AND tu_datasets._valid_to
    LEFT JOIN urls_to_datasets AS vp_datasets
        ON rt_joins.vp_base64_url = vp_datasets.base64_url
        AND rt_joins.vp_min_extract_ts BETWEEN vp_datasets._valid_from AND vp_datasets._valid_to
    LEFT JOIN urls_to_datasets AS schedule
        ON rt_joins.schedule_base64_url = schedule.base64_url
        AND LEAST(COALESCE(tu_min_ts, CAST("2099-01-01" AS TIMESTAMP)),
            COALESCE(vp_min_ts, CAST("2099-01-01" AS TIMESTAMP))) BETWEEN schedule._valid_from AND schedule._valid_to
    -- TODO: do we also want to join in schedule feed key here? we already have trip instance key that can traverse to schedule
)

SELECT * FROM fct_observed_trips
