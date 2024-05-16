WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ no_expired_services() }}
),

dim_calendar AS (
    SELECT * FROM {{ ref('dim_calendar') }}
),

dim_calendar_dates AS (
    SELECT * FROM {{ ref('dim_calendar_dates') }}
),

feed_calendar_service_expiration AS (
   SELECT
        feed_key,
        service_id,
        end_date
   FROM dim_calendar
),

feed_calendar_dates_service_expiration AS (
   SELECT
       feed_key,
       service_id,
       MAX(date) AS end_date
    FROM dim_calendar_dates
   GROUP BY 1, 2
),

feed_service_expiration AS (
   SELECT
        COALESCE(t1.feed_key, t2.feed_key) AS feed_key,
        COALESCE(t1.service_id, t2.service_id) AS service_id,
        GREATEST(COALESCE(t1.end_date, '1970-01-01'), COALESCE(t2.end_date, '1970-01-01')) AS service_end_date
   FROM feed_calendar_service_expiration AS t1
   FULL OUTER JOIN feed_calendar_dates_service_expiration AS t2
     ON t1.feed_key = t2.feed_key
    AND t1.service_id = t2.service_id
),

daily_earliest_service_expiration AS (
   SELECT
        feed_key,
        MIN(service_end_date) AS earliest_service_end_date
   FROM feed_service_expiration
  WHERE service_id IS NOT NULL
  GROUP BY 1
),

-- semi-arbitrarily just using calendar here because it's more common
check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_calendar
),

int_gtfs_quality__no_expired_services AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN exp.earliest_service_end_date >= date THEN {{ guidelines_pass_status() }}
                        -- TODO: could add special handling for April 16, 2021 (start of checks)
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN exp.earliest_service_end_date IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN exp.earliest_service_end_date < date THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN daily_earliest_service_expiration AS exp
        ON idx.schedule_feed_key = exp.feed_key
)

SELECT * FROM int_gtfs_quality__no_expired_services
