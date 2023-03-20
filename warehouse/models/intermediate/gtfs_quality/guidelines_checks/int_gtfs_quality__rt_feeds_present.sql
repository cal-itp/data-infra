WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ feed_present_trip_updates() }},
        {{ feed_present_vehicle_positions() }},
        {{ feed_present_service_alerts() }})
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM guideline_index
    WHERE had_rt_files
),

int_gtfs_quality__rt_feeds_present AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_rt_url_tu AND check = {{ feed_present_trip_updates() }})
                OR (idx.has_rt_url_vp AND check = {{ feed_present_vehicle_positions() }})
                OR (idx.has_rt_url_sa AND check = {{ feed_present_service_alerts() }})
                   THEN
                    CASE
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN had_rt_files THEN {{ guidelines_pass_status() }}
                        WHEN NOT had_rt_files THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
)

SELECT * FROM int_gtfs_quality__rt_feeds_present
