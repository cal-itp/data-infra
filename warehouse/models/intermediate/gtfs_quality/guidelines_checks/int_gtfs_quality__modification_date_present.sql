{{ config(materialized="table") }}

WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ modification_date_present() }}
),

fct_schedule_feed_downloads AS (
    SELECT *
      FROM {{ ref('fct_schedule_feed_downloads') }}
),

daily_schedule_feed_has_modification_date AS (
    SELECT
        feed_key,
        EXTRACT(DATE FROM ts) AS date,
        LOGICAL_OR(last_modified_timestamp IS NOT NULL) AS has_last_modified
      FROM fct_schedule_feed_downloads
     GROUP BY 1, 2
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM daily_schedule_feed_has_modification_date
),

int_gtfs_quality__modification_date_present AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        has_last_modified,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN idx.has_schedule_feed
                   THEN
                    CASE
                        WHEN has_last_modified THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN has_last_modified IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN NOT has_last_modified THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN daily_schedule_feed_has_modification_date AS has_mod_date
        ON idx.date = has_mod_date.date
        AND idx.schedule_feed_key = has_mod_date.feed_key
)

SELECT * FROM int_gtfs_quality__modification_date_present
