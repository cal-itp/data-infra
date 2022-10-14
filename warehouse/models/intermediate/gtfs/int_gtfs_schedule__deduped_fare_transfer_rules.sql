WITH stg_gtfs_schedule__fare_transfer_rules AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_transfer_rules') }}
),

int_gtfs_schedule__deduped_fare_transfer_rules AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__fare_transfer_rules',
        all_columns = [
            'base64_url',
            'ts',
            'from_leg_group_id',
            'to_leg_group_id',
            'transfer_count',
            'duration_limit',
            'duration_limit_type',
            'fare_transfer_type',
            'fare_product_id'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'from_leg_group_id',
            'to_leg_group_id',
            'fare_product_id',
            'transfer_count',
            'duration_limit'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_fare_transfer_rules
