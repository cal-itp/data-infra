WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__shapes'),
    ) }}
),

dim_shapes AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'shape_id', 'shape_pt_sequence']) }} AS key,
        feed_key,
        shape_id,
        shape_pt_lat,
        shape_pt_lon,
        shape_pt_sequence,
        shape_dist_traveled,
        base64_url,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_shapes
