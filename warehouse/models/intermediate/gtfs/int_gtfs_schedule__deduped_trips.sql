WITH

int_gtfs_schedule__deduped_trips AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__trips',
        all_columns = [
            'base64_url',
            'ts',
            'route_id',
            'service_id',
            'trip_id',
            'shape_id',
            'trip_headsign',
            'trip_short_name',
            'direction_id',
            'block_id',
            'wheelchair_accessible',
            'bikes_allowed'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'trip_id'
        ]) }}
)

SELECT * FROM int_gtfs_schedule__deduped_trips
