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
        stop_times.* EXCEPT(feed_key, trip_id, base64_url, feed_timezone, _feed_valid_from),
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


int_gtfs_schedule__frequencies_stop_times AS (
    SELECT
        feed_key,
        trip_id,
        stop_id,
        iteration_num,
        start_time_sec + iteration_num * headway_secs AS trip_start_time_sec,
        start_time_sec + iteration_num * headway_secs + (arrival_sec -first_trip_departure_sec) AS trip_stop_arrival_time_sec,
        start_time_sec + iteration_num * headway_secs + (departure_sec -first_trip_departure_sec) AS trip_stop_departure_time_sec,
        MAKE_INTERVAL(second => (start_time_sec + iteration_num * headway_secs)) AS trip_start_time_interval,
        MAKE_INTERVAL(second => start_time_sec + iteration_num * headway_secs + (arrival_sec -first_trip_departure_sec)) AS trip_stop_arrival_time_interval,
        stop_sequence,
        start_time AS frequency_start_time,
        end_time AS frequency_end_time,
        start_time_interval AS frequency_start_time_interval,
        end_time_interval AS frequency_end_time_interval,
        start_time_sec AS frequency_start_time_sec,
        end_time_sec AS frequency_end_time_sec,
        headway_secs,
        exact_times,
        first_trip_departure_sec,
        arrival_sec AS stop_times_arrival_sec,
        departure_sec AS stop_times_departure_sec,
        arrival_time_interval AS stop_times_arrival_time_interval,
        departure_time_interval AS stop_times_departure_time_interval,
        arrival_time AS stop_times_arrival_time,
        departure_time AS stop_times_departure_time,
        arrival_sec - first_trip_departure_sec AS sec_to_stop,
        stop_headsign,
        pickup_type,
        drop_off_type,
        shape_dist_traveled,
        timepoint,
        warning_duplicate_gtfs_key AS warning_duplicate_stop_times_primary_key,
        warning_missing_foreign_key_stop_id,
        base64_url,
        _feed_valid_from,
    FROM frequencies_stop_times
    LEFT JOIN UNNEST(GENERATE_ARRAY(start_time_sec, end_time_sec, headway_secs))
        AS iterations
        WITH OFFSET AS iteration_num
    -- if end time_sec = headway_secs * [some integer] + start_time_sec, then we're not actually supposed to have a trip that starts at end_time_sec
    WHERE start_time_sec + iteration_num * headway_secs < end_time_sec
    AND headway_secs > 0
)

SELECT * FROM int_gtfs_schedule__frequencies_stop_times
