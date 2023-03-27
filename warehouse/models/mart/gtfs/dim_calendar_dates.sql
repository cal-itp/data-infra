WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__calendar_dates'),
    ) }}
),

dim_calendar_dates AS (
    -- some full duplicate rows
    SELECT DISTINCT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'service_id', 'date']) }} AS key,
        feed_key,
        service_id,
        date,
        exception_type,
        base64_url,
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_calendar_dates
