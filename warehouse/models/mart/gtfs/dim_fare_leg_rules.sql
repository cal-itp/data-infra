WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_leg_rules'),
    ) }}
),

-- typical pattern for letting us join on nulls
with_identifier AS (
    SELECT *, {{ dbt_utils.surrogate_key(['network_id', 'from_area_id', 'to_area_id', 'fare_product_id']) }} AS fare_leg_rule_identifier,
    FROM make_dim
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        {{ dbt_utils.surrogate_key(['network_id', 'from_area_id', 'to_area_id', 'fare_product_id']) }} AS fare_leg_rule_identifier,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY 1, 2, 3
    HAVING COUNT(*) > 1
),

dim_fare_leg_rules AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'network_id', 'from_area_id', 'to_area_id', 'fare_product_id']) }} AS key,
        base64_url,
        feed_key,
        leg_group_id,
        network_id,
        from_area_id,
        to_area_id,
        fare_product_id,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM with_identifier
    LEFT JOIN bad_rows
        USING (base64_url, ts, fare_leg_rule_identifier)
)

SELECT * FROM dim_fare_leg_rules
