WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__stops'),
    ) }}
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        stop_id,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY base64_url, ts, stop_id
    HAVING COUNT(*) > 1
),

dim_stops AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'stop_id']) }} AS key,
        base64_url,
        feed_key,
        stop_id,
        tts_stop_name,
        stop_lat,
        stop_lon,
        ST_GEOGPOINT(
            stop_lon,
            stop_lat
        ) AS pt_geom,
        zone_id,
        parent_station,
        stop_code,
        stop_name,
        stop_desc,
        stop_url,
        location_type,
        stop_timezone,
        wheelchair_boarding,
        level_id,
        platform_code,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM make_dim
    LEFT JOIN bad_rows
        USING (base64_url, ts, stop_id)
)

SELECT * FROM dim_stops
