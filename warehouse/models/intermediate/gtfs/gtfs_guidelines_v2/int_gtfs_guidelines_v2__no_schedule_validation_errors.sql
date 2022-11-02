WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_guidelines_v2__feed_guideline_index') }}
    WHERE check = {{ no_validation_errors() }}
),

validation_notices AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

validation_errors_by_day AS (
    SELECT
        dim_schedule_feeds.key AS feed_key,
        validation_notices.dt AS date,
        SUM(total_notices) as validation_errors
    FROM validation_notices
    LEFT JOIN dim_schedule_feeds
        ON validation_notices.base64_url = dim_schedule_feeds.base64_url
            AND validation_notices.ts BETWEEN dim_schedule_feeds._valid_from AND dim_schedule_feeds._valid_to
    WHERE severity = "ERROR"
    GROUP BY 1, 2
),

int_gtfs_guidelines_v2__no_schedule_validation_errors AS (
    SELECT
        idx.date,
        idx.feed_key,
        check,
        feature,
        CASE
            WHEN validation_errors > 0 THEN "FAIL"
            WHEN validation_errors = 0 THEN "PASS"
        END AS status,
    FROM feed_guideline_index idx
    LEFT JOIN validation_errors_by_day errors
        ON idx.feed_key = errors.feed_key
            AND idx.date = errors.date
)

SELECT * FROM int_gtfs_guidelines_v2__no_schedule_validation_errors
