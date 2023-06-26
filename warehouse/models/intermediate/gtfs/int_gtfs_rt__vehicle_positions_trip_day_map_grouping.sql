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

WITH vehicle_positions AS (
    SELECT *,
        FIRST_VALUE(position_latitude)
            OVER
            (PARTITION BY
                base64_url,
                calculated_service_date,
                trip_id,
                trip_start_time
            ORDER BY COALESCE(vehicle_timestamp, header_timestamp, _extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS first_position_latitude,
        FIRST_VALUE(position_longitude)
            OVER
            (PARTITION BY
                base64_url,
                calculated_service_date,
                trip_id,
                trip_start_time
            ORDER BY COALESCE(vehicle_timestamp, header_timestamp, _extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS first_position_longitude,
        LAST_VALUE(position_latitude)
            OVER
            (PARTITION BY
                base64_url,
                calculated_service_date,
                trip_id,
                trip_start_time
            ORDER BY COALESCE(vehicle_timestamp, header_timestamp, _extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS last_position_latitude,
        LAST_VALUE(position_longitude)
            OVER
            (PARTITION BY
                base64_url,
                calculated_service_date,
                trip_id,
                trip_start_time
            ORDER BY COALESCE(vehicle_timestamp, header_timestamp, _extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS last_position_longitude,
    FROM {{ ref('fct_vehicle_positions_messages') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
grouped AS (
    SELECT
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
        schedule_base64_url,
        first_position_latitude,
        first_position_longitude,
        last_position_latitude,
        last_position_longitude,
        ARRAY_AGG(DISTINCT id) AS message_ids_array,
        ARRAY_AGG(DISTINCT header_timestamp) AS header_timestamps_array,
        ARRAY_AGG(DISTINCT vehicle_timestamp IGNORE NULLS) AS vehicle_timestamps_array,
        ARRAY_AGG(DISTINCT key) AS message_keys_array,
        ARRAY_AGG(DISTINCT _extract_ts) AS extract_ts_array,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
        MIN(vehicle_timestamp) AS min_vehicle_timestamp,
        MAX(vehicle_timestamp) AS max_vehicle_timestamp
    FROM vehicle_positions
    WHERE trip_id IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
),

int_gtfs_rt__vehicle_positions_trip_day_map_grouping AS (
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
        schedule_base64_url,
        first_position_latitude,
        first_position_longitude,
        last_position_latitude,
        last_position_longitude,
        message_ids_array,
        header_timestamps_array,
        vehicle_timestamps_array,
        message_keys_array,
        extract_ts_array,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp,
        min_vehicle_timestamp,
        max_vehicle_timestamp
    FROM grouped
)


SELECT * FROM int_gtfs_rt__vehicle_positions_trip_day_map_grouping
