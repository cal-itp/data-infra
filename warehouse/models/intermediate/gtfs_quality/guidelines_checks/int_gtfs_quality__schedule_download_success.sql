WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ static_feed_downloaded_successfully() }}
),

fct_schedule_feed_downloads AS (
    SELECT *,
           EXTRACT(date FROM ts) AS date
     FROM {{ ref('fct_schedule_feed_downloads') }}
),

daily_feed_download_unzip_success AS (
    SELECT DISTINCT date,
           base64_url
      FROM fct_schedule_feed_downloads
     WHERE download_success
       AND unzip_success
),

int_gtfs_quality__schedule_download_success AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN d.base64_url IS NOT null THEN {{ guidelines_pass_status() }}
            WHEN idx.has_schedule_url THEN {{ guidelines_fail_status() }}
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    LEFT JOIN daily_feed_download_unzip_success d
      ON idx.base64_url = d.base64_url
     AND idx.date = d.date
)

SELECT * FROM int_gtfs_quality__schedule_download_success
