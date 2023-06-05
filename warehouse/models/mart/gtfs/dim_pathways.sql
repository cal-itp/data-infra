WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__pathways'),
    ) }}
),

dim_pathways AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'pathway_id']) }} AS _gtfs_key,
        feed_key,
        pathway_id,
        from_stop_id,
        to_stop_id,
        pathway_mode,
        is_bidirectional,
        length,
        traversal_time,
        stair_count,
        max_slope,
        min_width,
        signposted_as,
        reversed_signposted_as,
        base64_url,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_pathways
