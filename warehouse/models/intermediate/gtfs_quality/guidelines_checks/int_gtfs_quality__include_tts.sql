WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ include_tts() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('dim_stops') }}
),

-- All feeds missing at least one tts_stop_name value
tts_issue_feeds AS (
   SELECT
       feed_key,
           -- When there is no tts_stop_name field for a given stop_name, or tts_stop_name is identical to stop_name, we proceed to run a few tests
        COUNTIF((tts_stop_name IS NULL OR tts_stop_name = stop_name)
         AND (
            -- Test 1: check for abbreviations that need to be spelled out, including directions (n, sb) and ROW types (st, rd)
            ---- EXISTS function returns true if the stop_name contains any of the listed "no-no words", and false if not
            EXISTS (
                  SELECT 1
                    -- Create an array of strings, called stop_name_parts, from stop_name
                    -- ie. 1234 North St becomes (1234,north,st)
                    FROM UNNEST(SPLIT(LOWER(stop_name), ' ')) stop_name_parts
                    -- Join stop_name_parts to list of "no-no words"
                    INNER JOIN UNNEST([
                                -- Directional abbreviations, ie "n" should read "north"
                                "n", "s", "e", "w", "ne", "se", "sw", "nw", "nb", "sb", "eb", "wb",
                                -- ROW abbreviations, ie "st" should read "street"
                                "st", "rd", "blvd", "hwy"
                    ]) tts_necessary_strings
                         ON stop_name_parts = tts_necessary_strings)
            -- Test 2: Check for >=2 adjacent numerals
            -- ie "21" should read "twenty one"
            OR REGEXP_CONTAINS(stop_name, '[0-9][0-9]')
            -- Test 3: Check for symbols that need be spelled out
            -- ie "pine/baker" should read "pine and baker"
            -- Note that the brackets are part of regex, and aren't on the "no-no character list"
            OR REGEXP_CONTAINS(stop_name, r'[/()]')
        )) AS ct_issues
    FROM dim_stops
    GROUP BY feed_key
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_stops
),

int_gtfs_quality__include_tts AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN ct_issues = 0 THEN {{ guidelines_pass_status() }}
                        -- TODO: could add special handling for April 16, 2021 (start of checks)
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN feed_key IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN ct_issues > 0 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN tts_issue_feeds
      ON idx.schedule_feed_key = tts_issue_feeds.feed_key
)

SELECT * FROM int_gtfs_quality__include_tts
