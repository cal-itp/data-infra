WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

fct_schedule_feed_downloads AS (
    SELECT *,
      FROM {{ ref('fct_schedule_feed_downloads')}}
),

daily_schedule_feed_downloads AS (
    SELECT feed_key,
           EXTRACT(date FROM ts) AS date,
           MAX(last_modified_timestamp) AS max_last_modified_timestamp
      FROM fct_schedule_feed_downloads
     GROUP BY 1,2
),

int_gtfs_quality__modification_date_present AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ modification_date_present() }} AS check,
        {{ best_practices_alignment_schedule() }} AS feature,
        CASE
            WHEN d.max_last_modified_timestamp IS NOT null THEN "PASS"
            WHEN d.feed_key IS NOT null AND d.max_last_modified_timestamp IS null THEN "FAIL"
            ELSE "N/A"
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_schedule_feed_downloads d
      ON idx.feed_key = d.feed_key
     AND idx.date = d.date
)

SELECT * FROM int_gtfs_quality__modification_date_present
