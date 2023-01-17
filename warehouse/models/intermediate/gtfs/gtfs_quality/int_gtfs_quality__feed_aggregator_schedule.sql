WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index_aggregator') }}
),

scraped_urls AS (
    SELECT *,
           -- turns both "https://website.com" and "http://website.com" into "website.com"
           RIGHT(feed_url_str,LENGTH(feed_url_str) - STRPOS(feed_url_str, "://") - 2) AS url_no_scheme
    FROM {{ ref('stg_gtfs_quality__scraped_urls') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

dim_gtfs_datasets AS (
    SELECT *,
           -- turns both "https://website.com" and "http://website.com" into "website.com"
           RIGHT(uri,LENGTH(uri) - STRPOS(uri, "://") - 2) AS url_no_scheme
    FROM {{ ref('dim_gtfs_datasets') }}
),

daily_scraped_urls AS (
    SELECT DISTINCT dt AS date,
           aggregator,
           url_no_scheme
      FROM scraped_urls
),

int_gtfs_quality__feed_aggregator_schedule AS (
    SELECT
        t1.date,
        t1.feed_key,
        t1.aggregator,
        CASE WHEN t1.aggregator = 'transitland' THEN {{ schedule_feed_on_transitland() }}
             WHEN t1.aggregator = 'mobility_database' THEN {{ schedule_feed_on_mobility_database() }}
             END AS check,
        {{ feed_aggregator_availability_schedule() }} AS feature,
        CASE
            WHEN t4.aggregator IS NOT null THEN "PASS"
            ELSE "FAIL"
        END AS status,
      FROM feed_guideline_index t1
      LEFT JOIN dim_schedule_feeds t2
        ON t2.key = t1.feed_key
      LEFT JOIN dim_gtfs_datasets t3
        ON t3.base64_url = t2.base64_url
      LEFT JOIN daily_scraped_urls AS t4
        ON t4.url_no_scheme = t3.url_no_scheme
       AND t4.date = t1.date
       AND t4.aggregator = t1.aggregator
)

SELECT * FROM int_gtfs_quality__feed_aggregator_schedule
