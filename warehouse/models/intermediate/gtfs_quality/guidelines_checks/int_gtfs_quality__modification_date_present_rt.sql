WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ modification_date_present_trip_updates() }},
        {{ modification_date_present_vehicle_positions() }},
        {{ modification_date_present_service_alerts() }})
),

unioned_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
),

daily_modification_date_status AS (
    SELECT dt AS date,
           base64_url,
           feed_type,
           LOGICAL_OR(last_modified_string IS NOT NULL) AS has_last_modified_string
      FROM unioned_parse_outcomes
     GROUP BY dt, base64_url, feed_type
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM daily_modification_date_status
),

int_gtfs_quality__modification_date_present_rt AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        has_last_modified_string,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_rt_feed_tu AND check = {{ modification_date_present_trip_updates() }})
                OR (idx.has_rt_feed_vp AND check = {{ modification_date_present_vehicle_positions() }})
                OR (idx.has_rt_feed_sa AND check = {{ modification_date_present_service_alerts() }})
                   THEN
                    CASE
                        WHEN has_last_modified_string THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN has_last_modified_string IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN NOT has_last_modified_string THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN daily_modification_date_status AS has_mod_date
        ON idx.date = has_mod_date.date
        AND idx.base64_url = has_mod_date.base64_url
)

SELECT * FROM int_gtfs_quality__modification_date_present_rt
