{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': '_feed_valid_from',
        'data_type': 'timestamp',
        'granularity': 'day',
    },
) }}

WITH dim_stop_times AS (
    SELECT
        *,
        CONCAT(arrival_time, "-", departure_time) AS time_pair,
    FROM {{ ref('dim_stop_times') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_feed_valid_from', filter_dt_column='_feed_valid_from', dev_lookback_days = None) }}
),

dim_stops AS (
    SELECT
        *,
        CONCAT(stop_lat, "-", stop_lon) AS stop_location
    FROM {{ ref('dim_stops') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_feed_valid_from', filter_dt_column='_feed_valid_from', dev_lookback_days = None) }}
),

dim_trips AS (
    SELECT *
    FROM {{ ref('dim_trips') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_feed_valid_from', filter_dt_column='_feed_valid_from', dev_lookback_days = None) }}
),

-- Aggregate information about each trip, including stops & stop times
int_gtfs_quality__scheduled_trip_version_summary AS (
    SELECT
        t1.feed_key,
        t1._feed_valid_from,
        t1.trip_id,
        t1.service_id,
        -- Creates a hash for a single field summarizing all stop_times this trip
        MD5(
            STRING_AGG(
                t2.time_pair, "-" ORDER BY t2.stop_sequence ASC
            )
        ) AS trip_stop_times_hash,
        -- Creates a hash for a single field summarizing all stop locations for this trip
        MD5(
            STRING_AGG(
                t3.stop_location, "-" ORDER BY t2.stop_sequence ASC
            )
        ) AS trip_stop_locations_hash
    FROM dim_trips t1
    LEFT JOIN dim_stop_times t2
        ON t2.trip_id = t1.trip_id
        AND t2.feed_key = t1.feed_key
    LEFT JOIN dim_stops t3
        ON t3.stop_id = t2.stop_id
        AND t3.feed_key = t2.feed_key
    -- SQLFluff gets mad about this for some reason
    GROUP BY 1, 2, 3, 4 -- noqa: AM06
)

SELECT * FROM int_gtfs_quality__scheduled_trip_version_summary
