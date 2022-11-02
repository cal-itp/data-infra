WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ include_tts() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

-- All feeds missing at least one tts_stop_name value
tts_issue_feeds AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at
    FROM dim_stops
    -- When there is no tts_stop_name field for a given stop_name, or tts_stop_name is identical to stop_name, we proceed to run a few tests
    WHERE (tts_stop_name IS null OR tts_stop_name = stop_name) AND
         (
            -- Test 1: check for abbreviations that need to be spelled out, including directions (n, sb) and ROW types (st, rd)
            ---- EXISTS function returns true if the stop_name contains any of the listed "no-no words", and false if not
            EXISTS (
                  SELECT 1
                    -- Create an array of strings, called stop_name_parts, from stop_name
                    -- ie. 1234 North St becomes (1234,north,st)
                    FROM UNNEST(SPLIT(LOWER(stop_name), ' ')) stop_name_parts
                    -- Join stop_name_parts to list of "no-no words"
                    JOIN UNNEST([
                                -- Directional abbreviations, ie "n" should read "north"
                                "n","s","e","w","ne","se","sw","nw","nb","sb","eb","wb",
                                -- ROW abbreviations, ie "st" should read "street"
                                "st","rd","blvd","hwy"
                    ]) tts_necessary_strings
                         ON stop_name_parts = tts_necessary_strings)
            -- Test 2: Check for >=2 adjacent numerals
            -- ie "21" should read "twenty one"
            OR REGEXP_CONTAINS(stop_name, '[0-9][0-9]')
            -- Test 3: Check for symbols that need be spelled out
            -- ie "pine/baker" should read "pine and baker"
            -- Note that the brackets are part of regex, and aren't on the "no-no character list"
            OR REGEXP_CONTAINS(stop_name, r'[/()]')
        )
   GROUP BY 1, 2, 3, 4
),

-- A daily count of feeds with at least one missing tts_stop_name value. It doesn't matter if one or more exist - the count is for dedupe purposes
daily_tts_issue_feeds AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    COUNTIF(t2.calitp_itp_id IS NOT null) AS tts_issue_feeds
  FROM feed_guideline_index AS t1
  LEFT JOIN tts_issue_feeds AS t2
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
        tts_issue_feeds,
        CASE
            WHEN tts_issue_feeds > 0 THEN "FAIL"
            WHEN tts_issue_feeds = 0 THEN "PASS"
        END AS status,
      FROM daily_tts_issue_feeds
)

SELECT * FROM tts_check
