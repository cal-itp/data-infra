WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__calendar_dates'),
    ) }}
),

dim_calendar_dates AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'service_id', 'date']) }} AS _gtfs_key,
        feed_key,
        service_id,
        date,
        exception_type,
        base64_url,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
    -- filter rather than flag; lots of downstream models expect uniqueness
    -- we could remove if we handled it everywhere but these are mostly full duplicates
    -- and they occur on many feeds
    QUALIFY ROW_NUMBER() OVER (PARTITION BY feed_key, service_id, date ORDER BY _line_number) = 1
)

SELECT * FROM dim_calendar_dates
