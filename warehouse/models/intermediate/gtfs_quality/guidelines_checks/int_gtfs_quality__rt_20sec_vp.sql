WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ rt_20sec_vp() }}
),


vp_message_ages AS (
    SELECT *
    FROM {{ ref('fct_daily_vehicle_positions_message_age_summary') }}
),

check_start AS (
    SELECT MIN(dt) AS first_check_date
    FROM vp_message_ages
),

int_gtfs_quality__rt_20sec_vp AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        p90_header_message_age,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN idx.has_rt_feed_vp
                   THEN
                    CASE
                        WHEN p90_header_message_age <= 20 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN p90_header_message_age IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN p90_header_message_age > 20 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN vp_message_ages
        ON idx.date = vp_message_ages.dt
        AND idx.base64_url = vp_message_ages.base64_url
)

SELECT * FROM int_gtfs_quality__rt_20sec_vp
