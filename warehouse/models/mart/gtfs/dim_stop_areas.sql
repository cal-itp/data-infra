WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__stop_areas'),
    ) }}
),

dim_stop_areas AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'area_id', 'stop_id']) }} AS key,
        feed_key,
        area_id,
        stop_id,
        base64_url,
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_stop_areas
