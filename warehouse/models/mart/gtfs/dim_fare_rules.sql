WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_rules'),
    ) }}
),

-- so we can reference twice
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS fare_rule_identifier,
    FROM make_dim
),

dim_fare_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_rule_identifier']) }} AS _gtfs_key,
        feed_key,
        fare_id,
        route_id,
        origin_id,
        destination_id,
        contains_id,
        base64_url,
        COUNT(*) OVER (PARTITION BY feed_key, fare_rule_identifier) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
)

SELECT * FROM dim_fare_rules
