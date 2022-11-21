WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
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
        COALESCE(t1.feed_key,t2.feed_key) AS feed_key,
        COALESCE(t1.service_id,t2.service_id) AS service_id,
        GREATEST(COALESCE(t1.end_date,'1970-01-01'),COALESCE(t2.end_date,'1970-01-01')) AS service_end_date
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
  WHERE service_id IS NOT null
  GROUP BY 1
),

int_gtfs_quality__no_expired_services AS (
    SELECT
        t1.date,
        t1.feed_key,
        {{ no_expired_services() }} AS check,
        {{ best_practices_alignment() }} AS feature,
        CASE
            WHEN t2.earliest_service_end_date < date THEN "FAIL"
            WHEN t2.earliest_service_end_date >= date THEN "PASS"
            ELSE "N/A"
        END AS status
      FROM feed_guideline_index AS t1
      LEFT JOIN daily_earliest_service_expiration AS t2
        ON t1.feed_key = t2.feed_key
)

SELECT * FROM int_gtfs_quality__no_expired_services
