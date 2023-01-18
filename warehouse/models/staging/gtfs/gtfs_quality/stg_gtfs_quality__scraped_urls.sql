WITH source AS (
    SELECT * FROM {{ source('feed_aggregator_scrapes', 'scraped_urls') }}
),

stg_gtfs_quality__scraped_urls AS (
    SELECT
        dt,
        ts,
        aggregator,
        key,
        name,
        feed_url_str,
        feed_type,
        raw_record,
    FROM source
)

SELECT * FROM stg_gtfs_quality__scraped_urls
