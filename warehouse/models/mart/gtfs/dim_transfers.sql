WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__transfers'),
    ) }}
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
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_transfers
