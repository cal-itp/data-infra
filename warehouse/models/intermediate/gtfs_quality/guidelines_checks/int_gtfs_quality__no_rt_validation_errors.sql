WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ no_rt_validation_errors_vp() }},
        {{ no_rt_validation_errors_tu() }},
        {{ no_rt_validation_errors_sa() }})
),

fct_daily_rt_feed_validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_validation_notices') }}
),

errors AS (
    SELECT
        date,
        base64_url,
        -- All error codes start with the letter E (warnings start with W)
        COUNTIF(code LIKE "E%" and total_notices > 0) > 0 AS had_errors
    FROM fct_daily_rt_feed_validation_notices
    GROUP BY 1, 2
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM errors
),

int_gtfs_quality__no_rt_validation_errors AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        had_errors,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_rt_feed_tu AND check = {{ no_rt_validation_errors_tu() }})
                OR (idx.has_rt_feed_vp AND check = {{ no_rt_validation_errors_vp() }})
                OR (idx.has_rt_feed_sa AND check = {{ no_rt_validation_errors_sa() }})
                   THEN
                    CASE
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN had_errors IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN NOT had_errors THEN {{ guidelines_pass_status() }}
                        WHEN had_errors THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN errors
        ON idx.date = errors.date
        AND idx.base64_url = errors.base64_url
)

SELECT * FROM int_gtfs_quality__no_rt_validation_errors
