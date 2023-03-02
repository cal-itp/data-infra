WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_url_guideline_index') }}
),

fct_schedule_feed_downloads AS (
    SELECT *,
           EXTRACT(date FROM ts) AS date
     FROM {{ ref('fct_schedule_feed_downloads') }}
),

daily_feed_download_unzip_success AS (
    SELECT date,
           base64_url
      FROM fct_schedule_feed_downloads
     WHERE download_success
       AND unzip_success
),

int_gtfs_quality__schedule_download_success AS (
    SELECT
        idx.date,
        idx.base64_url,
        {{ static_feed_downloaded_successfully() }} AS check,
        {{ compliance_schedule() }} AS feature,
        CASE
            WHEN LOGICAL_AND(d.base64_url IS NOT null) THEN {{ guidelines_pass_status() }}
            ELSE {{ guidelines_fail_status() }}
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_feed_download_unzip_success d
      ON idx.base64_url = d.base64_url
     AND idx.date = d.date
   GROUP BY 1, 2, 3, 4
)

SELECT * FROM int_gtfs_quality__schedule_download_success
