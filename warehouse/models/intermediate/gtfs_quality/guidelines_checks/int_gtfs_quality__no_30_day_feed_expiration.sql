WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ no_30_day_feed_expiration() }}
),

-- For this check we are only looking for the 30-day feed expiration warning
validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
    -- If the feed expires within 7 days, the 30day notice won't appear.
    -- In our case we want this check to fail even if the 7day expiration check also fails.
    WHERE code IN ('feed_expiration_date30_days', 'feed_expiration_date7_days')
),


validation_notices_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(total_notices) AS sum_total_notices
    FROM validation_notices
    GROUP BY feed_key, date
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM validation_notices
),

int_gtfs_quality__no_30_day_feed_expiration AS (
    SELECT
        idx.* EXCEPT(status),
        sum_total_notices,
        first_check_date,
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
    LEFT JOIN validation_notices_by_day
        ON idx.schedule_feed_key = validation_notices_by_day.feed_key
            AND idx.date = validation_notices_by_day.date
)

SELECT * FROM int_gtfs_quality__no_30_day_feed_expiration
