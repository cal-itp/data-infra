WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ shapes_valid() }}
),

-- For this check we are only looking for errors and warnings related to shapes
-- To investigate: there are many instances of error stop_too_far_from_trip_shape where n_notices = 0
validation_fact_daily_feed_codes_shape_related AS (
    SELECT * FROM {{ ref('validation_fact_daily_feed_codes') }}
    WHERE code IN (
            'decreasing_shape_distance',
            'equal_shape_distance_diff_coordinates',
            'equal_shape_distance_same_coordinates',
            'stops_match_shape_out_of_order',
            'stop_too_far_from_shape',
            'stop_too_far_from_shape_using_user_distance',
            'stop_too_far_from_trip_shape',
            'decreasing_or_equal_shape_distance'
            )
),

shape_validation_errors_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(n_notices) as validation_errors
    FROM validation_fact_daily_feed_codes_shape_related
    GROUP BY feed_key, date
),

shape_validation_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        -- validation_errors will only have a non-null value if the given day + feed_key appeared in validation_fact_daily_feed_codes_shape_related
        CASE
            WHEN t2.validation_errors IS null THEN "PASS"
        ELSE "FAIL"
        END AS status
      FROM feed_guideline_index t1
      LEFT JOIN shape_validation_errors_by_day t2
             ON t1.date = t2.date
            AND t1.feed_key = t2.feed_key
)

SELECT * FROM shape_validation_check
