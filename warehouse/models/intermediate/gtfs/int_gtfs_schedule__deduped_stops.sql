WITH stg_gtfs_schedule__stops AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__stops') }}
),

int_gtfs_schedule__deduped_stops AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__stops',
        all_columns = [
            'base64_url',
            'ts',
            'stop_id',
            'tts_stop_name',
            'stop_lat',
            'stop_lon',
            'zone_id',
            'parent_station',
            'stop_code',
            'stop_name',
            'stop_desc',
            'stop_url',
            'location_type',
            'stop_timezone',
            'wheelchair_boarding',
            'level_id',
            'platform_code'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'stop_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_stops
