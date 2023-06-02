WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__transfers'),
    ) }}
),

-- let us reference twice
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['from_stop_id', 'to_stop_id', 'from_trip_id', 'to_trip_id', 'from_route_id',' to_route_id']) }} AS transfer_identifier,
    FROM make_dim
),

dim_transfers AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'transfer_identifier']) }} AS _gtfs_key,
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
        COUNT(*) OVER (PARTITION BY feed_key, transfer_identifier) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
)

SELECT * FROM dim_transfers
