WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_feed_info AS (
    SELECT * FROM {{ ref('dim_feed_info') }}
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
    LEFT JOIN dim_feed_info AS t2
       ON t1.feed_key = t2.feed_key
    GROUP BY 1,2,3,4
)

SELECT * FROM int_gtfs_quality__technical_contact_listed
