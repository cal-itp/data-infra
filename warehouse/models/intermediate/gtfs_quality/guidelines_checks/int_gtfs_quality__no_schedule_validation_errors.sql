WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ no_validation_errors() }}
),

validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
),

validation_errors_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(total_notices) AS sum_total_notices
    FROM validation_notices
    WHERE severity = "ERROR"
    GROUP BY 1, 2
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM validation_notices
),

int_gtfs_quality__no_schedule_validation_errors AS (
    SELECT
        idx.* EXCEPT(status),
        sum_total_notices,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN sum_total_notices > 0 THEN {{ guidelines_fail_status() }}
                        WHEN sum_total_notices = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN sum_total_notices IS NULL THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN validation_errors_by_day
        ON idx.schedule_feed_key = validation_errors_by_day.feed_key
            AND idx.date = validation_errors_by_day.date
)

SELECT * FROM int_gtfs_quality__no_schedule_validation_errors
