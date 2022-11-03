WITH

validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_feed_validation_notices') }}
),

int_gtfs_guidelines_v2__no_schedule_validation_errors AS (
    SELECT
        feed_key,
        date,
        SUM(total_notices) AS sum_total_notices
    FROM validation_notices
    WHERE severity = "ERROR"
    GROUP BY 1, 2
)

SELECT * FROM int_gtfs_guidelines_v2__no_schedule_validation_errors
