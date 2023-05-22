WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__trips'),
    ) }}
),

dim_trips AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'trip_id']) }} AS key,
        base64_url,
        feed_key,
        route_id,
        service_id,
        trip_id,
        shape_id,
        trip_headsign,
        trip_short_name,
        direction_id,
        block_id,
        wheelchair_accessible,
        bikes_allowed,
        COUNT(*) OVER (PARTITION BY base64_url, ts, trip_id) > 1 AS warning_duplicate_primary_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_trips
