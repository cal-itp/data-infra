WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__stops'),
    ) }}
),

-- there are some feeds with missing stop_id which breaks everything
coalesce_missing_ids AS (
    SELECT
        *,
        COALESCE(stop_id, "") AS non_null_stop_id
    FROM make_dim
),

bad_rows AS (
    SELECT
        -- TODO: this could use feed_key instead of URL + ts (equivalent but maybe cleaner)
        base64_url,
        ts,
        stop_id,
        non_null_stop_id,
        TRUE AS warning_duplicate_primary_key
    FROM coalesce_missing_ids
    GROUP BY base64_url, ts, stop_id, non_null_stop_id
    HAVING COUNT(*) > 1
),

fill_in_tz AS (
    SELECT
        stops.*,
        COALESCE(parents.stop_timezone, stops.stop_timezone, stops.feed_timezone) AS stop_timezone_coalesced
    FROM coalesce_missing_ids AS stops
    LEFT JOIN coalesce_missing_ids AS parents
        ON stops.parent_station = parents.stop_id
        AND stops.feed_key = parents.feed_key
),

dim_stops AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['fill_in_tz.feed_key', 'fill_in_tz._line_number']) }} AS key,
        base64_url,
        fill_in_tz.feed_key,
        fill_in_tz.stop_id,
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
        fill_in_tz.stop_id IS NULL AS warning_missing_primary_key,
        stop_timezone_coalesced,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM fill_in_tz
    LEFT JOIN bad_rows
        USING (base64_url, ts, non_null_stop_id)
)

SELECT * FROM dim_stops
