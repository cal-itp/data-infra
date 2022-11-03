WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ no_expired_services() }}
),

stalest_calendar_services AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       MIN(end_date) AS end_date
    FROM {{ ref('calendar_clean') }}
   GROUP BY 1, 2, 3, 4
),

stalest_calendar_dates_services AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       MIN(date) AS date
    FROM {{ ref('calendar_dates_clean') }}
   GROUP BY 1, 2, 3, 4
),

daily_stalest_services AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    MIN(t2.end_date) AS min_end_date,
    MIN(t3.date) AS min_date
  FROM feed_guideline_index AS t1
  LEFT JOIN stalest_calendar_services AS t2
       ON t1.date >= t2.calitp_extracted_at
       AND t1.date < t2.calitp_deleted_at
       AND t1.calitp_itp_id = t2.calitp_itp_id
       AND t1.calitp_url_number = t2.calitp_url_number
  LEFT JOIN stalest_calendar_dates_services AS t3
       ON t1.date >= t3.calitp_extracted_at
       AND t1.date < t3.calitp_deleted_at
       AND t1.calitp_itp_id = t3.calitp_itp_id
       AND t1.calitp_url_number = t3.calitp_url_number
 GROUP BY 1, 2, 3, 4, 5, 6, 7
),

stale_service_check AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        feed_key,
        check,
        feature,
        min_end_date,
        min_date,
        CASE
            WHEN min_end_date < date OR min_date < date THEN "FAIL"
            WHEN min_end_date >= date OR min_date >= date THEN "PASS"
            ELSE "N/A"
        END AS status
      FROM daily_stalest_services
)

SELECT * FROM stale_service_check
