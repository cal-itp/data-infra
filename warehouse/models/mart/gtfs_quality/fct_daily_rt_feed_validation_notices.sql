{{ config(materialized='table') }}

WITH fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

codes AS (
    SELECT * FROM {{ ref('stg_gtfs_quality__rt_validation_code_descriptions') }}
),

outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_validation_outcomes') }}
),

notices AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_validation_notices') }}
),

-- This CTE starts with daily RT feeds, then pulls in validation outcomes
-- to give us a row per actual validation execution (outcome) that we have;
-- then cross-join codes to give us "buckets" per outcome since the
-- underlying notices will not contain a code that did not trigger a notice;
-- finally, we aggregate everything back up to the date/URL/code level
-- and count how many parsed and validated files we have, and sum the
-- notice occurrences; if we have successful validations but no occurrences,
-- we assume the feeds passed the code 100% of the time
fct_daily_rt_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.surrogate_key(['daily_feeds.date', 'daily_feeds.base64_url', 'codes.code', 'codes.is_critical']) }} AS key,
        daily_feeds.date,
        daily_feeds.base64_url,
        codes.code,
        codes.is_critical,
        -- TODO: at some point, these codes will be versioned by validator version
        ARRAY_AGG(DISTINCT notices.gtfs_validator_version IGNORE NULLS) AS gtfs_validator_versions,
        SUM(daily_feeds.parse_success_file_count) / COUNT(daily_feeds.key) AS parsed_files,
        COUNT(DISTINCT outcomes.extract_ts) AS validated_extracts,
        COUNTIF(outcomes.validation_success) AS validation_successes,
        COUNT(outcomes.validation_exception) AS validation_exceptions,
        COALESCE(
            SUM(ARRAY_LENGTH(occurrence_list)),
            CASE WHEN COUNTIF(outcomes.validation_success) > 0 THEN 0 END
        ) AS total_notices,
    FROM fct_daily_rt_feed_files AS daily_feeds
    LEFT JOIN outcomes
        ON daily_feeds.base64_url = outcomes.base64_url
        AND daily_feeds.date = EXTRACT(DATE FROM outcomes.extract_ts)
    CROSS JOIN codes
    LEFT JOIN notices
        ON outcomes.extract_ts = notices.ts
        AND outcomes.base64_url = notices.base64_url
        AND codes.code = notices.error_message_validation_rule_error_id
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM fct_daily_rt_feed_validation_notices
