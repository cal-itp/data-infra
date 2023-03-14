WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ rt_https_trip_updates() }},
        {{ rt_https_vehicle_positions() }},
        {{ rt_https_service_alerts() }})
),

rt_daily_url_index AS (
    SELECT DISTINCT
        dt,
        string_url,
        base64_url
    FROM {{ ref('int_gtfs_rt__daily_url_index') }}
),

check_start AS (
    SELECT MIN(dt) AS first_check_date
    FROM rt_daily_url_index
),

int_gtfs_quality__rt_https AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_rt_url_tu AND check = {{ rt_https_trip_updates() }})
                OR (idx.has_rt_url_vp AND check = {{ rt_https_vehicle_positions() }})
                OR (idx.has_rt_url_sa AND check = {{ rt_https_service_alerts() }})
                   THEN
                    CASE
                        WHEN string_url LIKE 'https%' THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN string_url IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN string_url NOT LIKE 'https%' THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN rt_daily_url_index AS urls
        ON idx.date = urls.dt
        AND idx.base64_url = urls.base64_url
)

SELECT * FROM int_gtfs_quality__rt_https
