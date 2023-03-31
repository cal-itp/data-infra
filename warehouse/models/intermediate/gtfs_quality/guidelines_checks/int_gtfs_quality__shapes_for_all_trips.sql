WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ shapes_for_all_trips() }}
),

dim_trips AS (
    SELECT * FROM {{ ref('dim_trips') }}
),

summarize_trips AS (
   SELECT
       feed_key,
       COUNTIF(shape_id IS NOT NULL) AS ct_shape_trips,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY 1
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_trips
),

int_gtfs_quality__shapes_for_all_trips AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN ct_shape_trips = ct_trips THEN {{ guidelines_pass_status() }}
                        -- TODO: we might be able to handle these if we wanted to shift to noon or similar -- only "too early" are on April 21, 2021 specifically
                        -- but impact is small (many checks not assessessed this far back) so probably not worth it right now
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        ELSE {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN summarize_trips
      ON idx.schedule_feed_key = summarize_trips.feed_key
)

SELECT * FROM int_gtfs_quality__shapes_for_all_trips
