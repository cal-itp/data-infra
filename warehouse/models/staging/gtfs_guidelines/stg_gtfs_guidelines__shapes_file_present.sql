WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ shapes_file_present() }}
),

daily_feed_shape_files AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feed_files') }}
    WHERE file_key = 'shapes.txt'
    -- On days where the extractor fails to download files for a feed, fact_daily_feed_files "interpolates" by using the previous day's files.
    -- By filtering on is_interpolated we capture only the days when the file didn't fail to download (ie was present)
      AND is_interpolated IS false
),

shapes_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        CASE
            WHEN t2.file_key IS NOT null THEN "PASS"
        ELSE "FAIL"
        END AS status
      FROM feed_guideline_index t1
      LEFT JOIN daily_feed_shape_files t2
             ON t1.date = t2.date
            AND t1.feed_key = t2.feed_key
)

SELECT * FROM shapes_check
