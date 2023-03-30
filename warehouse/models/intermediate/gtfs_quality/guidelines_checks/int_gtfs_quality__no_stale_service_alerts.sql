WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ no_stale_service_alerts() }}
),

sa_message_ages AS (
    SELECT *
    FROM {{ ref('fct_daily_service_alerts_message_age_summary') }}
),

check_start AS (
    SELECT MIN(dt) AS first_check_date
    FROM sa_message_ages
),

int_gtfs_quality__no_stale_service_alerts AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        p90_header_message_age,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN idx.has_rt_feed_sa
                   THEN
                    CASE
                        WHEN p90_header_message_age <= 600 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN p90_header_message_age IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN p90_header_message_age > 600 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN sa_message_ages
        ON idx.date = sa_message_ages.dt
        AND idx.base64_url = sa_message_ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_service_alerts
