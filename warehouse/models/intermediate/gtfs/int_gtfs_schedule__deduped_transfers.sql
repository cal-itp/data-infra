WITH stg_gtfs_schedule__transfers AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__transfers') }}
),

int_gtfs_schedule__deduped_transfers AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__transfers',
        all_columns = [
            'base64_url',
            'ts',
            'from_stop_id',
            'to_stop_id',
            'transfer_type',
            'from_route_id',
            'to_route_id',
            'from_trip_id',
            'to_trip_id',
            'min_transfer_time'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'from_stop_id',
            'to_stop_id',
            'from_trip_id',
            'to_trip_id',
            'from_route_id',
            'to_route_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_transfers
