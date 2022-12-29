WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_stops AS (
    SELECT * FROM {{ ref('dim_stops') }}
),

-- All feeds missing at least one tts_stop_name value
tts_issue_feeds AS (
   SELECT
       feed_key
    FROM dim_stops
    -- When there is no tts_stop_name field for a given stop_name, or tts_stop_name is identical to stop_name, we proceed to run a few tests
    WHERE (tts_stop_name IS null OR tts_stop_name = stop_name)
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
                                "st", "rd", "blvd", "hwy",
                                -- Especially in SoCal "la" has multiple uses with different pronunciation.
                                -- For example, "La Brea" and "LA Metro"
                                "la"
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
   GROUP BY feed_key
),

int_gtfs_quality__include_tts AS (
    SELECT
        t1.date,
        t1.feed_key,
        {{ include_tts() }} AS check,
        {{ accurate_accessibility_data() }} AS feature,
        CASE
            WHEN t2.feed_key IS NOT null THEN "FAIL"
            ELSE "PASS"
        END AS status,
      FROM feed_guideline_index t1
      LEFT JOIN tts_issue_feeds AS t2
        ON t1.feed_key = t2.feed_key
)

SELECT * FROM int_gtfs_quality__include_tts
