WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_products'),
    ) }}
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        fare_product_id,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY base64_url, ts, fare_product_id
    HAVING COUNT(*) > 1
),

dim_fare_products AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_product_id']) }} AS key,
        base64_url,
        feed_key,
        fare_product_id,
        fare_product_name,
        amount,
        currency,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM make_dim
    LEFT JOIN bad_rows
        USING (base64_url, ts, fare_product_id)
)

SELECT * FROM dim_fare_products
