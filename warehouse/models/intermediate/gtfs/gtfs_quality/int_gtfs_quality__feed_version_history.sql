WITH distinct_feed_versions AS (
    SELECT base64_url,
           key AS feed_key,
           _valid_from
      FROM {{ ref('dim_schedule_feeds') }}
),

-- Maps each feed_key to the feed_key of the previous version of that feed
int_gtfs_quality__feed_version_history AS (
    SELECT base64_url,
           feed_key,
           LAG (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS prev_feed_key,
           LEAD (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS next_feed_key,
           LEAD (EXTRACT(date FROM _valid_from)) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS next_feed_valid_from,
           EXTRACT(date FROM _valid_from) AS valid_from,
           ROW_NUMBER () OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) feed_version_number
      FROM distinct_feed_versions
)

SELECT * FROM int_gtfs_quality__feed_version_history
