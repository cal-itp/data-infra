WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
),

unioned_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
),

daily_modification_date_status AS (
    SELECT dt AS date,
           base64_url,
           feed_type,
           MAX(last_modified_string) AS max_last_modified_string
      FROM unioned_parse_outcomes
     GROUP BY dt, base64_url, feed_type
),

int_gtfs_quality__modification_date_present_rt AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        CASE WHEN idx.feed_type = 'service_alerts' THEN {{ modification_date_present_service_alerts() }}
             WHEN idx.feed_type = 'trip_updates' THEN {{ modification_date_present_trip_updates() }}
             WHEN idx.feed_type = 'vehicle_positions' THEN {{ modification_date_present_vehicle_positions() }}
        END AS check,
        {{ best_practices_alignment_rt() }} AS feature,
        CASE
            WHEN daily_mod_date.max_last_modified_string IS NOT null THEN {{ guidelines_pass_status() }}
            ELSE {{ guidelines_fail_status() }}
        END AS status
    FROM feed_guideline_index AS idx
    LEFT JOIN daily_modification_date_status AS daily_mod_date
    ON idx.date = daily_mod_date.date
   AND idx.base64_url = daily_mod_date.base64_url
   AND idx.feed_type = daily_mod_date.feed_type
)

SELECT * FROM int_gtfs_quality__modification_date_present_rt
