WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ no_expired_services() }}
),

daily_calendar_service_expiration AS (
   SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        t2.service_id,
        t2.end_date
   FROM feed_guideline_index AS t1
   LEFT JOIN {{ ref('calendar_clean') }} AS t2
     ON t1.date >= t2.calitp_extracted_at
    AND t1.date < t2.calitp_deleted_at
    AND t1.calitp_itp_id = t2.calitp_itp_id
    AND t1.calitp_url_number = t2.calitp_url_number
),

calendar_dates_service_expiration AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       service_id,
       MAX(date) AS end_date
    FROM {{ ref('calendar_dates_clean') }}
   GROUP BY 1, 2, 3, 4, 5
),

daily_calendar_dates_service_expiration AS (
   SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        t2.service_id,
        t2.end_date
   FROM feed_guideline_index AS t1
   LEFT JOIN calendar_dates_service_expiration AS t2
     ON t1.date >= t2.calitp_extracted_at
    AND t1.date < t2.calitp_deleted_at
    AND t1.calitp_itp_id = t2.calitp_itp_id
    AND t1.calitp_url_number = t2.calitp_url_number
),

daily_service_expiration AS (
   SELECT
        COALESCE(t1.date,t2.date) AS date,
        COALESCE(t1.calitp_itp_id,t2.calitp_itp_id) AS calitp_itp_id,
        COALESCE(t1.calitp_url_number,t2.calitp_url_number) AS calitp_url_number,
        COALESCE(t1.calitp_agency_name,t2.calitp_agency_name) AS calitp_agency_name,
        COALESCE(t1.feed_key,t2.feed_key) AS feed_key,
        COALESCE(t1.check,t2.check) AS check,
        COALESCE(t1.feature,t2.feature) AS feature,
        COALESCE(t1.service_id,t2.service_id) AS service_id,
        GREATEST(COALESCE(t1.end_date,'1970-01-01'),COALESCE(t2.end_date,'1970-01-01')) AS service_end_date
   FROM daily_calendar_service_expiration AS t1
   FULL OUTER JOIN daily_calendar_dates_service_expiration AS t2
     ON t1.date = t2.date
    AND t1.calitp_itp_id = t2.calitp_itp_id
    AND t1.calitp_url_number = t2.calitp_url_number
    AND t1.service_id = t2.service_id
),

daily_earliest_service_expiration AS (
   SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        feed_key,
        check,
        feature,
        MIN(service_end_date) AS earliest_service_end_date
   FROM daily_service_expiration
  WHERE service_id IS NOT null
  GROUP BY 1,2,3,4,5,6,7
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
        earliest_service_end_date,
        CASE
            WHEN earliest_service_end_date < date THEN "FAIL"
            WHEN earliest_service_end_date >= date THEN "PASS"
            ELSE "N/A"
        END AS status
      FROM daily_earliest_service_expiration
)

SELECT * FROM stale_service_check
