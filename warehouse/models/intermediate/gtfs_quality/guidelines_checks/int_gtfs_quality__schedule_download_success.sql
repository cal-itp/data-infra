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

daily_feed_download_unzip_status AS (
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
            -- only pass if both download and unzip succeeded
            WHEN download_success AND unzip_success THEN {{ guidelines_pass_status() }}
            -- if d.base_url is not null, that means we did attempt download on this day but either download or unzip did not succeed
            WHEN idx.has_schedule_url AND d.base64_url IS NOT NULL THEN {{ guidelines_fail_status() }}
            -- if d.base_url is null, means we did not attempt to download on this day for whatever reason (this URL is not present on right side of join)
            WHEN idx.has_schedule_url AND d.base64_url IS NULL THEN {{ guidelines_na_check_status() }}
            -- else statement fills in statuses that are pre-filled in the index like n/a - no entity
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    LEFT JOIN daily_feed_download_unzip_status d
      ON idx.base64_url = d.base64_url
     AND idx.date = d.date
)

SELECT * FROM int_gtfs_quality__schedule_url_download_success
