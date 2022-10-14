WITH stg_gtfs_schedule__feed_info AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__feed_info') }}
),

int_gtfs_schedule__deduped_feed_info AS (

    {{ util_dedupe_by_freq(table_name = 'stg_gtfs_schedule__feed_info',
        all_columns = [
            'base64_url',
            'ts',
            'feed_publisher_name',
            'feed_publisher_url',
            'feed_lang',
            'default_lang',
            'feed_version',
            'feed_contact_email',
            'feed_contact_url',
            'feed_start_date',
            'feed_end_date'
        ],
        dedupe_key = [
            'base64_url',
            'ts',
            'feed_publisher_name',
            'feed_publisher_url',
            'feed_lang',
            'default_lang',
            'feed_version',
            'feed_contact_email',
            'feed_contact_url',
            'feed_start_date',
            'feed_end_date'
        ]) }}
    )

SELECT * FROM int_gtfs_schedule__deduped_feed_info
