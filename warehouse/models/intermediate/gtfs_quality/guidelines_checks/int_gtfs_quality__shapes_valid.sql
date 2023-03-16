WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ shapes_valid() }}
),

files AS (
    SELECT * FROM {{ ref('fct_schedule_feed_files') }}
),

-- For this check we are only looking for errors related to shapes
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

feed_shape_validation_notices AS (
    SELECT
        feed_key,
        SUM(total_notices) AS validation_notices
    FROM shape_validation_notices
    GROUP BY 1
),

feed_has_shapes AS (
    SELECT
        feed_key,
        LOGICAL_OR(gtfs_filename = "shapes") AS has_shapes
    FROM files
    GROUP BY 1
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM shape_validation_notices
),

int_gtfs_quality__shapes_valid AS (
    SELECT
        idx.* EXCEPT(status),
        validation_notices,
        has_shapes,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN has_shapes AND validation_notices = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN feed_shape_validation_notices.feed_key IS NULL OR NOT has_shapes THEN {{ guidelines_na_check_status() }}
                        WHEN has_shapes AND validation_notices > 0 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_has_shapes
        ON idx.schedule_feed_key = feed_has_shapes.feed_key
    LEFT JOIN feed_shape_validation_notices
      ON idx.schedule_feed_key = feed_shape_validation_notices.feed_key
)

SELECT * FROM int_gtfs_quality__shapes_valid
