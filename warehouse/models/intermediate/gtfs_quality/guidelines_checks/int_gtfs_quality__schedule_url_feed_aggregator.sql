WITH guideline_index AS (
    SELECT
        *,
         {{ url_remove_scheme(from_url_safe_base64('base64_url')) }} AS no_scheme_url
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ schedule_feed_on_transitland() }}
        OR check = {{ schedule_feed_on_mobility_database() }}
),

daily_scraped_urls AS (
    SELECT DISTINCT dt AS date,
           aggregator,
           feed_url_str,
           {{ url_remove_scheme('feed_url_str') }} AS no_scheme_url,
           CASE
            WHEN aggregator = 'transitland' THEN {{ schedule_feed_on_transitland() }}
            WHEN aggregator = 'mobility_database' THEN {{ schedule_feed_on_mobility_database() }}
            END AS check,
      FROM scraped_urls
),

int_gtfs_quality__schedule_url_feed_aggregator AS (
    SELECT
        guideline_index.* EXCEPT(status),
        CASE
            WHEN daily_scraped_urls.aggregator IS NOT null THEN {{ guidelines_pass_status() }}
            WHEN guideline_index.has_schedule_url AND daily_scraped_urls.aggregator IS NULL THEN {{ guidelines_fail_status() }}
            ELSE guideline_index.status
        END AS status,
      FROM guideline_index
      LEFT JOIN daily_scraped_urls
        ON {{ url_remove_scheme('t4.feed_url_str') }} = {{ url_remove_scheme('t3.uri') }}
        AND guideline_index.date = daily_scraped_urls.date
        AND daily_scraped_urls.check = daily_scraped_urls.check
)

SELECT * FROM int_gtfs_quality__schedule_url_feed_aggregator
