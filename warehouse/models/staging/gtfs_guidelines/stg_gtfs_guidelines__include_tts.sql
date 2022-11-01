WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ include_tts() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

tts_issue_stops AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at
    FROM dim_stops
    WHERE (tts_stop_name IS null OR tts_stop_name = stop_name) AND
    -- "exists" statement checks whether stop name contains any words in a list.
    -- It performs this by breaking apart stop_name into an array, and then joining that array to an array of "no-no" words
    -- The alternative to this was a long repetitive query: "stop_name LIKE x OR stop_name LIKE y OR..."
         (
            -- EXISTS function returns true if the stop_name contains any of the listed strings, and false if not
            EXISTS (
                  SELECT 1
                    -- Create an array of strings from stop_name
                    -- ie. 1234 North St becomes (1234,north,st)
                    FROM UNNEST(SPLIT(LOWER(stop_name), ' ')) stop_name_parts
                    JOIN UNNEST([
                                -- directions, "n" should read "north"
                                "n","s","e","w","ne","se","sw","nw","nb","sb","eb","wb",
                                -- street suffixes, "st" should read "street"
                                "st","rd","blvd","hwy"
                    ]) tts_necessary_strings
                         ON stop_name_parts = tts_necessary_strings)
            -- 2 or more adjacent numbers, "21" should read "twenty one"
            OR REGEXP_CONTAINS(stop_name, '[0-9][0-9]')
            -- certain symbols, "pine/baker" should read "pine and baker"
            OR REGEXP_CONTAINS(stop_name, r'[/()]')
        )
   GROUP BY 1, 2, 3, 4
),

daily_tts_issue_stops AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    COUNTIF(t2.calitp_itp_id IS NOT null) AS tts_issues
  FROM feed_guideline_index AS t1
  LEFT JOIN tts_issue_stops AS t2
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
        tts_issues,
        CASE
            WHEN tts_issues > 0 THEN "FAIL"
            WHEN tts_issues = 0 THEN "PASS"
        END AS status,
      FROM daily_tts_issue_stops
)

SELECT * FROM tts_check
