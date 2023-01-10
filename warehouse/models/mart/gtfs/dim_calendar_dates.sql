WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__calendar_dates'),
    ) }}
),

dim_calendar_dates AS (
    -- some full duplicate rows
    SELECT DISTINCT
        {{ dbt_utils.surrogate_key(['feed_key', 'service_id', 'date']) }} AS key,
        feed_key,
        service_id,
        date,
        exception_type,
        base64_url,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_calendar_dates
