{{ config(materialized='table') }}

WITH validation_fact_daily_feed_notices AS (
    SELECT *
    FROM {{ ref('validation_fact_daily_feed_notices') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),


-- This view counts daily validation notices per feed and code
-- one row per individual code violation, within a feed, per day (where data exists)

-- Daily feeds crossed against codes. This is the full dimension table for our
-- result, so we RIGHT JOIN it in below to ensure we have feed x code, even
-- when n_notices is 0
date_range AS (
    SELECT DISTINCT date FROM validation_fact_daily_feed_notices
),

unique_codes AS (
    SELECT DISTINCT code FROM validation_fact_daily_feed_notices
),

daily_feed_cross_codes AS (
    SELECT
        t1.feed_key,
        t1.calitp_feed_id,   -- for final LAG below, removed from final table
        t2.date AS date,
        t3.code
    FROM gtfs_schedule_dim_feeds AS t1
    INNER JOIN date_range AS t2
        ON t1.calitp_extracted_at <= t2.date
            AND t1.calitp_deleted_at > t2.date
    CROSS JOIN unique_codes AS t3
),

-- combine tables to get entries for each level of date, feed on date, code
final_counts AS (
    SELECT
        feed_key,
        date,
        code,
        COUNT(*) AS n_notices
    FROM validation_fact_daily_feed_notices
    GROUP BY 1, 2, 3
),

final_count_lagged AS (
    SELECT
        T1.feed_key,
        T1.code,
        T1.date,
        LAG(T2.n_notices)
        OVER (PARTITION BY T1.calitp_feed_id, code ORDER BY date)
        AS prev_n_notices,
        COALESCE(T2.n_notices, 0) AS n_notices
    FROM daily_feed_cross_codes AS T1
    LEFT JOIN final_counts AS T2 USING (feed_key, code, date)

),

validation_fact_daily_feed_codes AS (
    SELECT
        * EXCEPT(prev_n_notices),
        n_notices - prev_n_notices AS diff_n_notices,
        (prev_n_notices > 0 AND n_notices = 0) AS is_error_resolved,
        COALESCE((prev_n_notices = 0 AND n_notices > 0), true) AS is_error_introduced
    FROM final_count_lagged
)

SELECT * FROM validation_fact_daily_feed_codes
