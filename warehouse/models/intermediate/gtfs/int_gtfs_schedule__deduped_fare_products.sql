WITH stg_gtfs_schedule__fare_products AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_products') }}
),

int_gtfs_schedule__deduped_fare_products AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__fare_products',
        all_columns = [
            'base64_url',
            'ts',
            'fare_product_id',
            'fare_product_name',
            'amount',
            'currency'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'fare_product_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_fare_products
