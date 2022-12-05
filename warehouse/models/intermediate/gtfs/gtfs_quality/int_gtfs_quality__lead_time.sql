WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_calendar AS (
    SELECT  *,
            -- Single field to represent the calendar for easy comparison
            CONCAT(CAST(monday AS string), CAST(tuesday AS string), CAST(wednesday AS string), CAST(thursday AS string),
                CAST(friday AS string), CAST(saturday AS string), CAST(sunday AS string)) AS day_combo
      FROM {{ ref('dim_calendar') }}
),

dim_calendar AS (
    SELECT  *,
    -- Add in calendar dates from here
      FROM {{ ref('dim_calendar') }}
),

dim_trips AS (
    SELECT  *,
    -- Add in trips from here, including stop times
      FROM {{ ref('dim_calendar') }}
),

distinct_feed_versions AS (
SELECT base64_url,
       key AS feed_key,
       _valid_from
  FROM {{ ref('dim_schedule_feeds') }}
 WHERE key IS NOT null
),

feed_version_history AS (
SELECT base64_url,
       feed_key,
       LAG (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS previous_feed_key,
       EXTRACT(date FROM _valid_from) AS valid_from
  FROM distinct_feed_versions
 ORDER BY base64_url
),

calendar_joined AS (
  SELECT t1.base64_url,
         t1.feed_key,
         t1.valid_from,
         DATE_DIFF(valid_from, cal.start_date, DAY) AS days_since_start_date,
         DATE_DIFF(cal.end_date, valid_from, DAY) AS days_until_end_date
    FROM feed_version_history AS t1
    JOIN dim_calendar AS cal
      ON t1.feed_key = cal.feed_key
    LEFT JOIN dim_calendar AS prev_cal
      ON t1.previous_feed_key = prev_cal.feed_key
     AND cal.service_id = prev_cal.service_id
),

daily_improper_calendar_updates AS (
  SELECT feed_key,
         valid_from AS date,
         COUNT(*) AS updates
    FROM calendar_joined
   WHERE (cal_day_combo != prev_cal_day_combo
          OR prev_cal_day_combo IS null)
         -- Start date is no later than 7 days from now (can be in the past)
         AND days_since_start_date > -7
         -- End date is in the future
         AND days_until_end_date > 0
   GROUP BY 1,2
),

feed_update_count AS (
    SELECT t1.date,
           t1.feed_key,
           SUM(t2.updates)
               OVER (
                   PARTITION BY t2.feed_key
                   ORDER BY t2.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS updates_last_30_days
      FROM feed_guideline_index AS t1
      LEFT JOIN daily_improper_calendar_updates AS t2
        ON t1.feed_key = t2.feed_key
),

int_gtfs_quality__lead_time AS (
    SELECT date,
           feed_key,
           {{ lead_time() }} AS check,
           {{ up_to_dateness() }} AS feature,
           CASE WHEN updates_last_30_days > 0 THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM feed_update_count
)

SELECT * FROM int_gtfs_quality__lead_time
