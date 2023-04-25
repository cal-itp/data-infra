WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__stop_times'),
    ) }}
),

make_intervals AS (
    SELECT
        *,
        -- INTERVAL type allows us to handle times past midnight (ex. 26:30:30)
        -- see: https://gtfs.org/schedule/reference/#field-types for how GTFS defines a "Time"
        CASE
            WHEN REGEXP_CONTAINS(arrival_time, "^[0-9]+:[0-5][0-9]:[0-5][0-9]$") THEN CAST(arrival_time AS INTERVAL)
        END AS arrival_time_interval,
        CASE
            WHEN REGEXP_CONTAINS(departure_time, "^[0-9]+:[0-5][0-9]:[0-5][0-9]$") THEN CAST(departure_time AS INTERVAL)
        END AS departure_time_interval
    FROM make_dim
),

dim_stop_times AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'trip_id', 'stop_sequence']) }} AS key,
        base64_url,
        feed_key,
        trip_id,
        stop_id,
        stop_sequence,
        arrival_time,
        departure_time,
        -- we could test that extract days from these intervals is 0 but it shouldn't be necessary
        -- BQ does not automatically justify hours to days because # hours per day varies based on daylight savings
        arrival_time_interval,
        departure_time_interval,
        stop_headsign,
        pickup_type,
        drop_off_type,
        continuous_pickup,
        continuous_drop_off,
        shape_dist_traveled,
        timepoint,
        COUNT(
            *
        ) OVER (
            PARTITION BY base64_url, ts, trip_id, stop_sequence
        ) > 1 AS warning_duplicate_primary_key,
        stop_id IS NULL AS warning_missing_foreign_key_stop_id,
        _feed_valid_from,
        feed_timezone,
        EXTRACT(HOUR FROM arrival_time_interval) * 3600
            + EXTRACT(MINUTE FROM arrival_time_interval) * 60
            + EXTRACT(SECOND FROM arrival_time_interval) AS arrival_sec,
        EXTRACT(HOUR FROM departure_time_interval) * 3600
            + EXTRACT(MINUTE FROM departure_time_interval) * 60
            + EXTRACT(SECOND FROM departure_time_interval) AS departure_sec,
    FROM make_intervals
)

SELECT * FROM dim_stop_times
