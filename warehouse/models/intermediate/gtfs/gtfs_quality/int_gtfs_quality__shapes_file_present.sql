WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

keyed_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__keyed_parse_outcomes')}}
),

fct_schedule_feed_downloads AS (
    SELECT * FROM {{ ref('fct_schedule_feed_downloads')}}
),

feed_download_status AS (
    SELECT feed_key,
           EXTRACT(date FROM ts) AS date,
           LOGICAL_AND(download_success) AS daily_download_success,
           LOGICAL_AND(unzip_success) AS daily_unzip_success
      FROM fct_schedule_feed_downloads
     GROUP BY 1,2
),

daily_feed_download_success AS (
    SELECT feed_key,
           date
      FROM feed_download_status
     WHERE daily_download_success
       AND daily_unzip_success
),

feed_shapes_present_status AS (
    SELECT feed_key,
           dt AS date,
           LOGICAL_AND(parse_success) AS daily_parse_success
      FROM keyed_parse_outcomes
     WHERE gtfs_filename = 'shapes'
       AND feed_key IS NOT null
     GROUP BY 1,2
),

daily_feed_shapes_present AS (
    SELECT feed_key,
           date
      FROM feed_shapes_present_status
     WHERE daily_parse_success
),

feed_shapes_present AS (
    SELECT feed_key,
           dt AS date,
      FROM keyed_parse_outcomes
     WHERE parse_success
       AND gtfs_filename = 'shapes'
       AND feed_key IS NOT null
),

int_gtfs_quality__shapes_file_present AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ shapes_file_present() }} AS check,
        {{ accurate_service_data() }} AS feature,
        CASE
            -- Shapes file is present
            WHEN s.feed_key IS NOT null THEN "PASS"
            -- Shapes file is NOT present, feed downloaded successfully
            WHEN s.feed_key IS null AND d.feed_key IS NOT null THEN "FAIL"
            -- Shapes file is NOT present, feed failed to download
            WHEN s.feed_key IS null AND d.feed_key IS NULL THEN null
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_feed_shapes_present s
      ON idx.feed_key = s.feed_key
     AND idx.date = s.date
    LEFT JOIN daily_feed_download_success d
      ON idx.feed_key = d.feed_key
     AND idx.date = d.date
)

SELECT * FROM int_gtfs_quality__shapes_file_present
