WITH stg_gtfs_schedule__fare_rules AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_rules') }}
),

int_gtfs_schedule__deduped_fare_rules AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__fare_rules',
        all_columns = [
            'base64_url',
            'ts',
            'fare_id',
            'route_id',
            'origin_id',
            'destination_id',
            'contains_id'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'fare_id',
            'route_id',
            'origin_id',
            'destination_id',
            'contains_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_fare_rules
