WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__areas'),
    ) }}
),

dim_areas AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'area_id']) }} AS _gtfs_key,
        feed_key,
        area_id,
        area_name,
        base64_url,
        COUNT(
            *
        ) OVER (
            PARTITION BY feed_key, area_id
        ) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_areas
