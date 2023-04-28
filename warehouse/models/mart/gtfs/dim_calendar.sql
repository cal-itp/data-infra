WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__calendar'),
    ) }}
),

dim_calendar AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'service_id']) }} AS key,
        feed_key,
        service_id,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        start_date,
        end_date,
        base64_url,
        _feed_valid_from,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_calendar
