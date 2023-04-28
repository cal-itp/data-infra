WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__areas'),
    ) }}
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        area_id,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY base64_url, ts, area_id
    HAVING COUNT(*) > 1
),

dim_areas AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'area_id']) }} AS key,
        feed_key,
        area_id,
        area_name,
        base64_url,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
        feed_timezone,
    FROM make_dim
    LEFT JOIN bad_rows
        USING (base64_url, ts, area_id)
)

SELECT * FROM dim_areas
