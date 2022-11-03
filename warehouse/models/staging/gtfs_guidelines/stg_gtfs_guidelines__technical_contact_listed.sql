WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ technical_contact_listed() }}
),

feed_info_clean AS (
    SELECT * FROM {{ ref('feed_info_clean') }}
),

-- Joins our feed-level check with feed_guideline_index, where each feed will have a row for every day it is active
daily_technical_contact_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        CASE
            WHEN t2.feed_contact_email IS NOT null THEN "PASS"
            ELSE "FAIL"
        END AS status,
        COUNT(*)
    FROM feed_guideline_index AS t1
    LEFT JOIN feed_info_clean AS t2
       ON t1.calitp_itp_id = t2.calitp_itp_id
      AND t1.calitp_url_number = t2.calitp_url_number
      AND t1.date >= t2.calitp_extracted_at
      AND t1.date < t2.calitp_deleted_at
    GROUP BY 1,2,3,4,5,6,7
),

daily_technical_contact_check_dedupe AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        check,
        feature,
        status
    FROM daily_technical_contact_check
)

SELECT * FROM daily_technical_contact_check_dedupe
