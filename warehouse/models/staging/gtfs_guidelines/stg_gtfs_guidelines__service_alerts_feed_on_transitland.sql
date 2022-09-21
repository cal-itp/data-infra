WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ service_alerts_feed_on_transitland() }}
),

fact_daily_transitland_url_check AS (
SELECT * FROM {{ ref('stg_gtfs_guidelines__fact_daily_transitland_url_check') }}
),

service_alerts_daily_check AS (
    SELECT
        DISTINCT calitp_itp_id,
        dt AS date
   FROM fact_daily_transitland_url_check
  WHERE url_type = "gtfs_rt_service_alerts_url"
    AND transitland_status = 'present'
),

-- Note: since calitp_url_number is not available in fact_daily_transitland_url_check, this is a bit of a fuzzy join - to be improved after refactor
feed_daily_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        CASE
            WHEN t2.calitp_itp_id IS NOT null THEN "PASS"
        ELSE "FAIL"
        END AS status,
    FROM feed_guideline_index AS t1
    LEFT JOIN service_alerts_daily_check AS t2
         ON t1.calitp_itp_id = t2.calitp_itp_id
         AND t1.date = t2.date
)

SELECT * FROM feed_daily_check
