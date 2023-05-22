WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_transfer_rules'),
    ) }}
),

-- typical pattern for letting us join on nulls
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['from_leg_group_id', 'to_leg_group_id', 'fare_product_id', 'transfer_count', 'duration_limit']) }} AS fare_transfer_rule_identifier,
    FROM make_dim
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        {{ dbt_utils.generate_surrogate_key(['from_leg_group_id', 'to_leg_group_id', 'fare_product_id', 'transfer_count', 'duration_limit']) }} AS fare_transfer_rule_identifier,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY 1, 2, 3
    HAVING COUNT(*) > 1
),

dim_fare_transfer_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'from_leg_group_id', 'to_leg_group_id', 'fare_product_id', 'transfer_count', 'duration_limit']) }} AS key,
        base64_url,
        feed_key,
        from_leg_group_id,
        to_leg_group_id,
        transfer_count,
        duration_limit,
        duration_limit_type,
        fare_transfer_type,
        fare_product_id,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
    LEFT JOIN bad_rows
        USING (base64_url, ts, fare_transfer_rule_identifier)
)

SELECT * FROM dim_fare_transfer_rules
