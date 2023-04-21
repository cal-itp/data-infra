{{ config(materialized = "table") }}

WITH frequencies AS (
    SELECT * FROM {{ ref('dim_frequencies') }}
),

stop_times AS (
    SELECT * FROM {{ ref('dim_stop_times') }}
),

frequencies_stop_times AS (
    SELECT
        frequencies.*,
        stop_times.* EXCEPT(feed_key, trip_id),
        LAST_VALUE(arrival_sec)
            OVER(
                PARTITION BY feed_key, trip_id
                ORDER BY stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS final_trip_arrival_sec,
        FIRST_VALUE(departure_sec)
            OVER(
                PARTITION BY feed_key, trip_id
                ORDER BY stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS first_trip_departure_sec
    FROM frequencies
    INNER JOIN stop_times
    USING (feed_key, trip_id)
),

trip_durations AS (
    SELECT DISTINCT
        feed_key,
        trip_id,
        final_trip_arrival_sec - first_trip_departure_sec AS trip_duration_sec,
        final_trip_arrival_sec,
        first_trip_departure_sec,
    FROM frequencies_stop_times
),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT
        frequencies.feed_key,
        frequencies.trip_id,
        start_time,
        end_time,
        start_time_interval,
        end_time_interval,
        start_time_sec,
        end_time_sec,
        headway_secs,
        exact_times,
        trip_duration_sec,
        final_trip_arrival_sec,
        first_trip_departure_sec,
        base64_url,
        _feed_valid_from,
    FROM frequencies
    LEFT JOIN trip_durations
        USING (feed_key, trip_id)
)

SELECT * FROM int_gtfs_schedule__frequencies_stop_times
