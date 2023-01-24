WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_rules'),
    ) }}
),

dim_fare_rules AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS key,
        feed_key,
        fare_id,
        route_id,
        origin_id,
        destination_id,
        contains_id,
        base64_url,
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_fare_rules
