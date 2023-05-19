{{ config(materialized='table') }}

WITH

dim_stop_times AS (
    SELECT * FROM {{ ref('dim_stop_times') }}
),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__frequencies_stop_times') }}
    WHERE stop_id IS NOT NULL
),

stops AS (
    SELECT
        feed_key,
        stop_id,
        stop_timezone_coalesced,
        COUNT(*) AS ct
    FROM {{ ref('dim_stops') }}
    WHERE stop_id IS NOT NULL
    GROUP BY 1, 2, 3
    -- we can have duplicate stop IDs within a given feed (this is not valid, but happens)
    -- just keep the most common time zone (very unlikely to have same stop ID but different time zone)
    QUALIFY RANK() OVER (PARTITION BY feed_key, stop_id ORDER BY ct DESC) = 1
),

stops_times_with_tz AS (
    SELECT
        dim_stop_times.* EXCEPT(departure_sec, arrival_sec),
        COALESCE(freq.trip_stop_arrival_time_sec, arrival_sec) AS trip_stop_arrival_sec,
        freq.trip_start_time_sec,
        dim_stop_times.departure_sec AS trip_stop_departure_sec,
        freq.iteration_num,
        freq.exact_times,
        freq.trip_id IS NOT NULL AS frequencies_defined_trip,
        COALESCE(FIRST_VALUE(stop_timezone_coalesced)
            OVER (PARTITION BY feed_key, trip_id
                ORDER BY dim_stop_times.stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), feed_timezone) AS trip_start_timezone,
        COALESCE(LAST_VALUE(stop_timezone_coalesced)
            OVER (PARTITION BY feed_key, trip_id
                ORDER BY dim_stop_times.stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), feed_timezone) AS trip_end_timezone
    FROM dim_stop_times
    LEFT JOIN stops
        USING (feed_key, stop_id)
    LEFT JOIN int_gtfs_schedule__frequencies_stop_times freq
        USING (feed_key, trip_id, stop_id)
),

grouped AS (
    SELECT
        trip_id,
        feed_key,
        base64_url,
        feed_timezone,
        trip_start_timezone,
        trip_end_timezone,
        iteration_num,
        exact_times,
        COUNT(DISTINCT stop_id) AS num_distinct_stops_served,
        COUNT(*) AS num_stop_times,
        -- note: not using the interval columns here because the interval type doesn't support aggregation
        -- so we'd probably have to lean on seconds/window functions anyway
        -- for frequency based trips, we have trip_start_time_sec, else just use departure sec
        COALESCE(MIN(trip_start_time_sec), MIN(trip_stop_departure_sec)) AS trip_first_departure_sec,
        MAX(trip_stop_arrival_sec) AS trip_last_arrival_sec,
        (MAX(trip_stop_arrival_sec) - COALESCE(MIN(trip_start_time_sec), MIN(trip_stop_departure_sec))) / 3600 AS service_hours,
        (MAX(end_pickup_drop_off_window_sec) -  MIN(start_pickup_drop_off_window_sec)) / 3600 AS flex_service_hours,
        LOGICAL_OR(
            warning_duplicate_primary_key
        ) AS contains_warning_duplicate_primary_key,
        LOGICAL_OR(
            warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id,
        LOGICAL_OR(
            frequencies_defined_trip
        ) AS frequencies_defined_trip,
        -- per: https://docs.google.com/spreadsheets/d/1iqvzJV_YWmFyYGtpbO2dqGMbf4XEjvar3rt9SxHU-xY/edit#gid=0
        -- determine flex usage by presence of these two fields for any row in stop times
        LOGICAL_AND(
            start_pickup_drop_off_window IS NOT NULL
            AND end_pickup_drop_off_window IS NOT NULL) AS is_gtfs_flex_trip,
        COUNTIF(start_pickup_drop_off_window IS NOT NULL
            AND end_pickup_drop_off_window IS NOT NULL) AS num_gtfs_flex_stop_times,
        MIN(start_pickup_drop_off_window_sec) AS first_start_pickup_drop_off_window_sec,
        MAX(end_pickup_drop_off_window_sec) AS last_end_pickup_drop_off_window_sec,

        -- see: https://gtfs.org/schedule/reference/#stop_timestxt for the enum definitions on the following fields
        -- including default value definitions
        {{ countif_enum_with_default('pickup_type', value_to_check = 0, default_value = 0) }} AS num_regularly_scheduled_pickup_stop_times,
        {{ countif_enum_with_default('pickup_type', value_to_check = 1, default_value = 0) }} AS num_no_pickup_stop_times,
        {{ countif_enum_with_default('pickup_type', value_to_check = 2, default_value = 0) }} AS num_phone_call_required_for_pickup_stop_times,
        {{ countif_enum_with_default('pickup_type', value_to_check = 3, default_value = 0) }} AS num_coordinate_pickup_with_driver_stop_times,
        {{ countif_enum_with_default('drop_off_type', value_to_check = 0, default_value = 0) }} AS num_regularly_scheduled_drop_off_stop_times,
        {{ countif_enum_with_default('drop_off_type', value_to_check = 1, default_value = 0) }} AS num_no_drop_off_stop_times,
        {{ countif_enum_with_default('drop_off_type', value_to_check = 2, default_value = 0) }} AS num_phone_call_required_for_drop_off_stop_times,
        {{ countif_enum_with_default('drop_off_type', value_to_check = 3, default_value = 0) }} AS num_coordinate_drop_off_with_driver_stop_times,

        {{ countif_enum_with_default('continuous_pickup', value_to_check = 0, default_value = 1) }} AS num_continuous_pickup_stop_times,
        {{ countif_enum_with_default('continuous_pickup', value_to_check = 1, default_value = 1) }} AS num_no_continuous_pickup_stop_times,
        {{ countif_enum_with_default('continuous_pickup', value_to_check = 2, default_value = 1) }} AS num_phone_call_required_for_continuous_pickup_stop_times,
        {{ countif_enum_with_default('continuous_pickup', value_to_check = 3, default_value = 1) }} AS num_coordinate_continuous_pickup_with_driver_stop_times,
        {{ countif_enum_with_default('continuous_drop_off', value_to_check = 0, default_value = 1) }} AS num_continuous_drop_off_stop_times,
        {{ countif_enum_with_default('continuous_drop_off', value_to_check = 1, default_value = 1) }}  AS num_no_continuous_drop_off_stop_times,
        {{ countif_enum_with_default('continuous_drop_off', value_to_check = 2, default_value = 1) }}  AS num_phone_call_required_for_continuous_drop_off_stop_times,
        {{ countif_enum_with_default('continuous_drop_off', value_to_check = 3, default_value = 1) }}  AS num_coordinate_continuous_drop_off_with_driver_stop_times,

        {{ countif_enum_with_default('timepoint', value_to_check = 0, default_value = 1) }}  AS num_approximate_timepoint_stop_times,
        {{ countif_enum_with_default('timepoint', value_to_check = 1, default_value = 1) }} AS num_exact_timepoint_stop_times,

        COUNTIF(
            arrival_time IS NOT NULL
        ) AS num_arrival_times_populated_stop_times,

        COUNTIF(
            departure_time IS NOT NULL
        ) AS num_departure_times_populated_stop_times,

    FROM stops_times_with_tz
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

int_gtfs_schedule__stop_times_grouped AS (
    SELECT
        trip_id,
        feed_key,
        base64_url,
        feed_timezone,
        trip_start_timezone,
        trip_end_timezone,
        iteration_num,
        exact_times,
        num_distinct_stops_served,
        num_stop_times,
        trip_first_departure_sec,
        trip_last_arrival_sec,
        service_hours,
        flex_service_hours,
        contains_warning_duplicate_primary_key,
        contains_warning_missing_foreign_key_stop_id,
        frequencies_defined_trip,
        is_gtfs_flex_trip,
        NOT(num_no_pickup_stop_times = num_stop_times
                AND num_no_drop_off_stop_times = num_stop_times
                AND num_no_continuous_pickup_stop_times = num_stop_times
                AND num_no_continuous_drop_off_stop_times = num_stop_times)
            AS has_rider_service,
        is_gtfs_flex_trip OR (
            num_phone_call_required_for_pickup_stop_times = num_stop_times
            AND num_phone_call_required_for_drop_off_stop_times = num_stop_times
            ) AS is_entirely_demand_responsive_trip,
        num_gtfs_flex_stop_times,
        first_start_pickup_drop_off_window_sec,
        last_end_pickup_drop_off_window_sec,
        num_regularly_scheduled_pickup_stop_times,
        num_no_pickup_stop_times,
        num_phone_call_required_for_pickup_stop_times,
        num_coordinate_pickup_with_driver_stop_times,
        num_regularly_scheduled_drop_off_stop_times,
        num_no_drop_off_stop_times,
        num_phone_call_required_for_drop_off_stop_times,
        num_coordinate_drop_off_with_driver_stop_times,

        num_continuous_pickup_stop_times,
        num_no_continuous_pickup_stop_times,
        num_phone_call_required_for_continuous_pickup_stop_times,
        num_coordinate_continuous_pickup_with_driver_stop_times,
        num_continuous_drop_off_stop_times,
        num_no_continuous_drop_off_stop_times,
        num_phone_call_required_for_continuous_drop_off_stop_times,
        num_coordinate_continuous_drop_off_with_driver_stop_times,

        num_approximate_timepoint_stop_times,
        num_exact_timepoint_stop_times,
        num_arrival_times_populated_stop_times,
        num_departure_times_populated_stop_times
    FROM grouped
)

SELECT * FROM int_gtfs_schedule__stop_times_grouped
