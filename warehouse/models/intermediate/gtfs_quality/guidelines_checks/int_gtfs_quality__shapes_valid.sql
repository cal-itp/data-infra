WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ shapes_valid() }}
),

shape_validation_notices AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
    WHERE code IN (
            'decreasing_shape_distance',
            'equal_shape_distance_diff_coordinates',
            'equal_shape_distance_same_coordinates',
            'decreasing_or_equal_shape_distance'
            )
),

-- For this check we are only looking for errors related to shapes
feed_shape_validation_notices AS (
    SELECT
        feed_key,
        SUM(total_notices) AS validation_notices
    FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
    WHERE code IN (
            'decreasing_shape_distance',
            'equal_shape_distance_diff_coordinates',
            'equal_shape_distance_same_coordinates',
            'decreasing_or_equal_shape_distance'
            )
    GROUP BY feed_key
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM shape_validation_notices
),

int_gtfs_quality__shapes_valid AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN validation_notices = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN feed_key IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN validation_notices > 0 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_shape_validation_notices
      ON idx.schedule_feed_key = feed_shape_validation_notices.feed_key
)

SELECT * FROM int_gtfs_quality__shapes_valid
