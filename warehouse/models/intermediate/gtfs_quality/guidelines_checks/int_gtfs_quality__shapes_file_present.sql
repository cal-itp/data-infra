WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ shapes_file_present() }}
),

keyed_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__keyed_parse_outcomes') }}
),

daily_feed_shapes_present AS (
    SELECT feed_key
      FROM keyed_parse_outcomes
     WHERE parse_success
       AND gtfs_filename = 'shapes'
       AND feed_key IS NOT null
),

check_start AS (
    SELECT MIN(dt) AS first_check_date
    FROM keyed_parse_outcomes
),

int_gtfs_quality__shapes_file_present AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN s.feed_key IS NOT null THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        ELSE {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN daily_feed_shapes_present s
      ON idx.schedule_feed_key = s.feed_key
)

SELECT * FROM int_gtfs_quality__shapes_file_present
