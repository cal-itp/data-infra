WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

daily_feed_shapes_present AS (
    SELECT feed_key,
           EXTRACT(date FROM ts) AS date,
           -- zipfile_files is an array which may contain "shapes.txt" but may also contain a string like "google_transit/shapes.txt".
           -- this long EXISTS statement solves for both
           CASE WHEN EXISTS(SELECT * FROM UNNEST(zipfile_files) AS x WHERE LOWER(x) LIKE '%shapes.txt') THEN true
                ELSE false
           END AS has_shapes
      FROM `cal-itp-data-infra-staging`.`owades_mart_gtfs`.`fct_schedule_feed_downloads`
      -- If download or unzip fails, that is a different issue than a missing shapes file
     WHERE download_success
       AND unzip_success
),

int_gtfs_quality__shapes_file_present AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ shapes_file_present() }} AS check,
        {{ accurate_service_data() }} AS feature,
        -- Status will be null in cases where feed had download or unzip failure
        CASE
            WHEN has_shapes THEN "PASS"
            WHEN NOT(has_shapes) THEN "FAIL"
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN daily_feed_shapes_present s
        ON idx.feed_key = s.feed_key
            AND idx.date = s.date
)

SELECT * FROM int_gtfs_quality__shapes_file_present
