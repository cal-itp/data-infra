WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_transfer_rules'),
    ) }}
),

-- so we can reference twice
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['from_leg_group_id', 'to_leg_group_id', 'fare_product_id', 'transfer_count', 'duration_limit']) }} AS fare_transfer_rule_identifier,
    FROM make_dim
),

dim_fare_transfer_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_transfer_rule_identifier']) }} AS _gtfs_key,
        base64_url,
        feed_key,
        from_leg_group_id,
        to_leg_group_id,
        transfer_count,
        duration_limit,
        duration_limit_type,
        fare_transfer_type,
        fare_product_id,
        COUNT(*) OVER (PARTITION BY feed_key, fare_transfer_rule_identifier) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
    -- also remove full duplicates (early fares data)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY feed_key, fare_transfer_rule_identifier, duration_limit_type, fare_transfer_type, fare_product_id ORDER BY _line_number) = 1
)

SELECT * FROM dim_fare_transfer_rules
