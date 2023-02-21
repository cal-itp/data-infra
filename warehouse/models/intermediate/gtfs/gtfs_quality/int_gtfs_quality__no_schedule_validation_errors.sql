WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
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

int_gtfs_quality__no_schedule_validation_errors AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ no_validation_errors() }} AS check,
        {{ compliance_schedule() }} AS feature,
        CASE
            WHEN sum_total_notices > 0 THEN {{ guidelines_fail_status() }}
            WHEN sum_total_notices = 0 THEN {{ guidelines_pass_status() }}
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN validation_errors_by_day
        ON idx.feed_key = validation_errors_by_day.feed_key
            AND idx.date = validation_errors_by_day.date
)

SELECT * FROM int_gtfs_quality__no_schedule_validation_errors
