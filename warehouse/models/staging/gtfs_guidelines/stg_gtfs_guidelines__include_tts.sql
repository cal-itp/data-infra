WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ include_tts() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

summarize_stops AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       COUNTIF((tts_stop_name IS null OR tts_stop_name = stop_name)
                AND
        -- Examples guided by https://docs.google.com/document/d/1LObjgDyiiE6UBiA3GpoNOlZ36li-KKj6dwBzRTDa7VU
                (
                -- Cardinal directions, check start and end of stop names for each direction.
                -- Must be in CAPSf to be caught
                -- "N" should read "north"
                    stop_name LIKE '% N'OR
                    stop_name LIKE 'N %'OR
                    stop_name LIKE '% NE'OR
                    stop_name LIKE 'NE %'OR
                    stop_name LIKE '% E'OR
                    stop_name LIKE 'E %'OR
                    stop_name LIKE '% SE'OR
                    stop_name LIKE 'SE %'OR
                    stop_name LIKE '% S'OR
                    stop_name LIKE 'S %'OR
                    stop_name LIKE '% SW'OR
                    stop_name LIKE 'SW %'OR
                    stop_name LIKE '% W'OR
                    stop_name LIKE 'W %'OR
                    stop_name LIKE '% NW' OR
                    stop_name LIKE 'NW %' OR
                -- Street names, must end name or be standalone word
                -- "st" should read "street"
                    LOWER(stop_name) LIKE '% st' OR
                    LOWER(stop_name) LIKE '% st %' OR
                    LOWER(stop_name) LIKE '% rd' OR
                    LOWER(stop_name) LIKE '% rd %' OR
                -- "blvd" and "hwy" are distinctive enough to flag in all cases
                -- "blvd" should read "boulevard"
                    LOWER(stop_name) LIKE '%blvd%' OR
                    LOWER(stop_name) LIKE '%hwy%' OR
                -- "Pine/Baker" should read "pine and baker"
                    stop_name LIKE '%/%' OR
                    stop_name LIKE '%(%' OR
                    stop_name LIKE '%)%' OR
                -- "21" should read "twenty one"
                    REGEXP_CONTAINS(stop_name, '[0-9][0-9]')
                )
        ) AS ct_tts_issues,
    FROM dim_stops
   GROUP BY 1, 2, 3, 4
),

daily_stops AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    SUM(t2.ct_tts_issues) AS tot_tts_issues
  FROM feed_guideline_index AS t1
  LEFT JOIN summarize_stops AS t2
       ON t1.date >= t2.calitp_extracted_at
       AND t1.date < t2.calitp_deleted_at
       AND t1.calitp_itp_id = t2.calitp_itp_id
       AND t1.calitp_url_number = t2.calitp_url_number
 GROUP BY
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature
),

tts_check AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        feed_key,
        check,
        feature,
        tot_tts_issues,
        CASE
            WHEN tot_tts_issues = 0 THEN "PASS"
            WHEN tot_tts_issues > 0 THEN "FAIL"
        END AS status,
      FROM daily_stops
)

SELECT * FROM tts_check
