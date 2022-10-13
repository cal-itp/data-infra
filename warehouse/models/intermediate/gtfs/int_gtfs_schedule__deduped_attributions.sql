WITH stg_gtfs_schedule__attributions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__attributions') }}
),

int_gtfs_schedule__deduped_attributions AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__attributions',
        all_columns = [
            'base64_url',
            'ts',
            'organization_name',
            'attribution_id',
            'agency_id',
            'route_id',
            'trip_id',
            'is_producer',
            'is_operator',
            'is_authority',
            'attribution_url',
            'attribution_email',
            'attribution_phone'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'attribution_id'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_attributions
