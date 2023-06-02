WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_leg_rules'),
    ) }}
),

-- so we can reference this in two places
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['network_id', 'from_area_id', 'to_area_id', 'fare_product_id']) }} AS fare_leg_rule_identifier,
    FROM make_dim
),

dim_fare_leg_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_leg_rule_identifier']) }} AS _gtfs_key,
        base64_url,
        feed_key,
        leg_group_id,
        network_id,
        from_area_id,
        to_area_id,
        fare_product_id,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
    QUALIFY ROW_NUMBER() OVER (PARTITION BY feed_key, fare_leg_rule_identifier ORDER BY _line_number) = 1
)

SELECT * FROM dim_fare_leg_rules
