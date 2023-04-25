WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__frequencies'),
    ) }}
),

dim_frequencies AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'trip_id', 'start_time']) }} AS key,
        feed_key,
        trip_id,
        start_time,
        end_time,
        headway_secs,
        exact_times,
        base64_url,
        _feed_valid_from,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_frequencies
