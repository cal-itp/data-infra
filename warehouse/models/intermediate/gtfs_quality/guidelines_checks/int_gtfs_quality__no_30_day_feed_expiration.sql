WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

-- For this check we are only looking for the 30-day feed expiration warning
validation_fact_daily_feed_codes_shape_related AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
     WHERE code = 'feed_expiration_date30_days'
),

validation_notices_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(total_notices) as validation_notices
    FROM validation_fact_daily_feed_codes_shape_related
    GROUP BY feed_key, date
),

int_gtfs_quality__no_30_day_feed_expiration AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ no_30_day_feed_expiration() }} AS check,
        {{ best_practices_alignment_schedule() }} AS feature,
        CASE
            WHEN notices.validation_notices = 0 THEN {{ guidelines_pass_status() }}
            WHEN notices.validation_notices > 0 THEN {{ guidelines_fail_status() }}
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN validation_notices_by_day notices
        ON idx.feed_key = notices.feed_key
            AND idx.date = notices.date
)

SELECT * FROM int_gtfs_quality__no_30_day_feed_expiration
