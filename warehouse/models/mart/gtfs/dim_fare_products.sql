WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_products'),
    ) }}
),

dim_fare_products AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_product_id']) }} AS _gtfs_key,
        base64_url,
        feed_key,
        fare_product_id,
        fare_product_name,
        fare_media_id,
        amount,
        currency,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
    QUALIFY ROW_NUMBER() OVER (PARTITION BY feed_key, fare_product_id ORDER BY _line_number) = 1
)

SELECT * FROM dim_fare_products
