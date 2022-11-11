WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

feed_info AS (
    SELECT
        feed_key,
        feed_contact_email,
        EXTRACT(date FROM _valid_from) AS valid_from_date,
        EXTRACT(date FROM _valid_to) AS valid_to_date
      FROM {{ ref('dim_feed_info') }}
),

-- Joins our feed-level check with feed_guideline_index, where each feed will have a row for every day it is active
int_gtfs_quality__technical_contact_listed AS (
    SELECT
        t1.date,
        t1.feed_key,
        {{ technical_contact_listed() }} AS check,
        {{ technical_contact_availability() }} AS feature,
        CASE
            WHEN LOGICAL_AND(t2.feed_contact_email IS NOT NULL) THEN "PASS"
            ELSE "FAIL"
        END AS status
    FROM feed_guideline_index AS t1
    LEFT JOIN feed_info AS t2
       ON t1.feed_key = t2.feed_key
      AND t1.date >= t2.valid_from_date
      AND t1.date <= t2.valid_to_date
    GROUP BY 1,2,3,4
)

SELECT * FROM int_gtfs_quality__technical_contact_listed
