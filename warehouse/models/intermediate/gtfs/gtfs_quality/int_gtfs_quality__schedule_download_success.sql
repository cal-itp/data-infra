WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

daily_feed_download_unzip_success AS (
    SELECT feed_key
      FROM {{ ref('fct_schedule_feed_downloads') }}
     WHERE download_success
       AND unzip_success
),

int_gtfs_quality__schedule_download_success AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ static_feed_downloaded_successfully() }} AS check,
        {{ compliance() }} AS feature,
        CASE
            WHEN LOGICAL_AND(d.feed_key IS NOT null) THEN "PASS"
            ELSE "FAIL"
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_feed_download_unzip_success d
      ON idx.feed_key = d.feed_key
   GROUP BY 1,2,3,4
)

SELECT * FROM int_gtfs_quality__schedule_download_success