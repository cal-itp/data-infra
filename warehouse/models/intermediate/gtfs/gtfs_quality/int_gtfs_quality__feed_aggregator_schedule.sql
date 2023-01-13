WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

-- cross-join feed_guideline_index with manual list of aggregators (so there's a row for each)

scraped_urls AS (
    SELECT * FROM {{ ref('stg_gtfs_quality__scraped_urls') }}
),

daily_scraped_urls AS (
    SELECT DISTINCT dt,
           aggregator,
           feed_url_str
      FROM scraped_urls
),

int_gtfs_quality__feed_aggregator_schedule AS (
    SELECT
        t1.date,
        t1.feed_key,
        CASE WHEN t4.aggregator = 'transitland' THEN {{ schedule_feed_on_transitland() }}
             WHEN t4.aggregator = 'md' THEN {{ schedule_feed_on_mobility_database() }}
             END AS check,
        {{ feed_aggregator_availability_schedule() }} AS feature,
        CASE
            WHEN t4.aggregator IS NOT null THEN "PASS"
            ELSE "FAIL"
        END AS status,
      FROM feed_guideline_index t1
      LEFT JOIN dim_feed_info t2
        ON t1.feed_key = t2.feed_key
      LEFT JOIN dim_gtfs_datasets t3
        ON t2.base64_url = t3.base64_url
      LEFT JOIN daily_scraped_urls AS t4
        ON t3.uri = t4.feed_url_str
       AND t1.aggregator = t4.aggregator
)

SELECT * FROM int_gtfs_quality__feed_aggregator_schedule
