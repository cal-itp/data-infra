WITH stg_gtfs_schedule__fare_leg_rules AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_leg_rules') }}
),

int_gtfs_schedule__deduped_fare_leg_rules AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__fare_leg_rules',
        all_columns = [
            'base64_url',
            'ts',
            'leg_group_id',
            'network_id',
            'from_area_id',
            'to_area_id',
            'fare_product_id'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'network_id',
            'from_area_id',
            'to_area_id',
            'fare_product_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_fare_leg_rules
