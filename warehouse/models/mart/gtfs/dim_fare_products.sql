WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_products'),
    ) }}
),

dim_fare_products AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'fare_product_id']) }} AS key,
        base64_url,
        feed_key,
        fare_product_id,
        fare_product_name,
        amount,
        currency,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_fare_products
