{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages_unnested') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
        -- TODO: support route_id/direction_id/start_time as a trip identifier
        -- as of 2023-04-20, there are no cases of service alert messages where trip ID is not populated and trip.route ID is populated
        -- so if trip_id is not populated we assume it's not a trip-level alert
        AND trip_id IS NOT NULL
),

-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
grouped AS (
    SELECT
        dt,
        calculated_service_date,
        service_alerts.base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        schedule_feed_timezone,
        -- what we really want here is an array of the distinct structs, but you can't DISTINCT structs
        -- so we turn them into JSON strings which we can turn back into structs later
        ARRAY_AGG(DISTINCT
            TO_JSON_STRING(
                STRUCT<message_id string, cause string, effect string, header string, description string >
                (id, cause, effect, header_text_text, description_text_text)
                )) AS alert_content_array,
        ARRAY_AGG(DISTINCT id) AS message_ids_array,
        ARRAY_AGG(DISTINCT _extract_ts) AS extract_ts_array,
        ARRAY_AGG(DISTINCT header_timestamp) AS header_timestamps_array,
        ARRAY_AGG(DISTINCT service_alert_message_key) AS message_keys_array,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
    FROM service_alerts
    -- we only want to use alerts that were actually *active*
    WHERE header_timestamp BETWEEN active_period_start_ts AND active_period_end_ts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

int_gtfs_rt__service_alerts_trip_day_map_grouping AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        -- this key is not unique yet here but will be on the downstream final model
        {{ dbt_utils.generate_surrogate_key([
            'calculated_service_date',
            'base64_url',
            'trip_id',
            'trip_start_time',
        ]) }} as key,
        dt,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        schedule_feed_timezone,
        alert_content_array,
        message_ids_array,
        extract_ts_array,
        header_timestamps_array,
        message_keys_array,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp,
    FROM grouped
)

SELECT * FROM int_gtfs_rt__service_alerts_trip_day_map_grouping
