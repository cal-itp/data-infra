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
    SELECT date,
           base64_url,
           LOGICAL_OR(download_success) AS download_success,
           LOGICAL_OR(unzip_success) AS unzip_success
      FROM fct_schedule_feed_downloads
      GROUP BY 1, 2
),

int_gtfs_quality__schedule_url_download_success AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN download_success AND unzip_success THEN {{ guidelines_pass_status() }}
            -- means we attempted to download and failed
            WHEN idx.has_schedule_url AND d.base64_url IS NOT NULL THEN {{ guidelines_fail_status() }}
            -- means we did not attempt to download on this day for whatever reason
            WHEN idx.has_schedule_url AND d.base64_url IS NULL THEN {{ guidelines_na_check_status() }}
            -- fill in n/a entities etc.
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    LEFT JOIN daily_feed_download_unzip_success d
      ON idx.base64_url = d.base64_url
     AND idx.date = d.date
)

SELECT * FROM int_gtfs_quality__schedule_url_download_success
