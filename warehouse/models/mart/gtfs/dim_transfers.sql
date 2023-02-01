WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__transfers'),
    ) }}
),

-- typical pattern for letting us join on nulls
with_identifier AS (
    SELECT *, {{ dbt_utils.surrogate_key(['from_stop_id', 'to_stop_id', 'from_trip_id', 'to_trip_id', 'from_route_id',' to_route_id']) }} AS transfer_identifier,
    FROM make_dim
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        {{ dbt_utils.surrogate_key(['from_stop_id', 'to_stop_id', 'from_trip_id', 'to_trip_id', 'from_route_id',' to_route_id']) }} AS transfer_identifier,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY 1, 2, 3
    HAVING COUNT(*) > 1
),

dim_transfers AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'from_stop_id', 'to_stop_id', 'from_trip_id', 'to_trip_id', 'from_route_id',' to_route_id']) }} AS key,
        feed_key,
        from_stop_id,
        to_stop_id,
        transfer_type,
        from_route_id,
        to_route_id,
        from_trip_id,
        to_trip_id,
        min_transfer_time,
        base64_url,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM with_identifier
    LEFT JOIN bad_rows
        USING (base64_url, ts, transfer_identifier)
)

SELECT * FROM dim_transfers
