{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_fare_products AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_fare_products') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_fare_products') }}
),

dim_fare_products AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'fare_product_id']) }} AS key,
        base64_url,
        feed_key,
        gtfs_dataset_key,
        fare_product_id,
        fare_product_name,
        amount,
        currency,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_fare_products
