WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_leg_rules'),
    ) }}
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
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_fare_leg_rules
