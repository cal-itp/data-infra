WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

keyed_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__keyed_parse_outcomes')}}
),

daily_feed_shapes_present AS (
    SELECT feed_key
      FROM keyed_parse_outcomes
     WHERE parse_success
       AND gtfs_filename = 'shapes'
       AND feed_key IS NOT null
),

int_gtfs_quality__shapes_file_present AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ shapes_file_present() }} AS check,
        {{ accurate_service_data() }} AS feature,
        CASE
            WHEN s.feed_key IS NOT null THEN "PASS"
            ELSE "FAIL"
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_feed_shapes_present s
      ON idx.feed_key = s.feed_key
)

SELECT * FROM int_gtfs_quality__shapes_file_present
