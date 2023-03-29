WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_rules'),
    ) }}
),

-- typical pattern for letting us join on nulls
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS fare_rule_identifier,
    FROM make_dim
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        {{ dbt_utils.generate_surrogate_key(['fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS fare_rule_identifier,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY 1, 2, 3
    HAVING COUNT(*) > 1
),

dim_fare_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS key,
        feed_key,
        fare_id,
        route_id,
        origin_id,
        destination_id,
        contains_id,
        base64_url,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM with_identifier
    LEFT JOIN bad_rows
        USING (base64_url, ts, fare_rule_identifier)
)

SELECT * FROM dim_fare_rules
