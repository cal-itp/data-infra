{{ config(materialized='table') }}

WITH daily_feeds_codes AS (
    SELECT
        daily_feeds.date,
        daily_feeds.base64_url,
        daily_feeds.key,
        daily_feeds.parse_success_file_count,
        codes.code,
        codes.description,
        codes.is_critical
    FROM {{ ref('fct_daily_rt_feed_files') }} AS daily_feeds
    CROSS JOIN {{ ref('stg_gtfs_quality__rt_validation_code_descriptions') }} AS codes
),

outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_validation_outcomes') }}
),

notices AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_validation_notices') }}
),

-- This table reports on each entry in the daily GTFS-RT feeds table.
-- For each feed, on each day, create a row for the codes table, which
-- contains a potential validation error with its description and error level.
-- For each feed/day/code, retrieve outcomes and notices, then report on
-- the total number of extractions, successes, exceptions, occurrences of
-- that specific code, and the GTFS-RT validator version used.
-- If a code does not appear for a feed on a day, total_notices will be 0.
-- If there a feed was not validated on a day, total_notices will be NULL.
fct_daily_rt_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['daily_feeds_codes.date', 'daily_feeds_codes.base64_url', 'daily_feeds_codes.code', 'daily_feeds_codes.is_critical']) }} AS key,
        daily_feeds_codes.date,
        daily_feeds_codes.base64_url,
        daily_feeds_codes.code,
        daily_feeds_codes.description,
        daily_feeds_codes.is_critical,
        -- TODO: at some point, these codes will be versioned by validator version
        ARRAY_AGG(DISTINCT notices.gtfs_validator_version IGNORE NULLS) AS gtfs_validator_versions,
        SUM(daily_feeds_codes.parse_success_file_count) / COUNT(daily_feeds_codes.key) AS parsed_files,
        COUNT(DISTINCT outcomes.extract_ts) AS validated_extracts,
        COUNTIF(outcomes.validation_success) AS validation_successes,
        COUNT(outcomes.validation_exception) AS validation_exceptions,
        COALESCE(
          SUM(ARRAY_LENGTH(notices.occurrence_list)),
          CASE WHEN COUNTIF(outcomes.validation_success) > 0 THEN 0 END
        ) AS total_notices
    FROM daily_feeds_codes
    LEFT JOIN outcomes
         ON daily_feeds_codes.base64_url = outcomes.base64_url
         AND daily_feeds_codes.date = EXTRACT(DATE FROM outcomes.extract_ts)
    LEFT JOIN notices
         ON outcomes.extract_ts = notices.ts
         AND daily_feeds_codes.base64_url = notices.base64_url
         AND daily_feeds_codes.code = notices.error_message_validation_rule_error_id
    GROUP BY
        daily_feeds_codes.date,
        daily_feeds_codes.base64_url,
        daily_feeds_codes.code,
        daily_feeds_codes.description,
        daily_feeds_codes.is_critical
)

SELECT * FROM fct_daily_rt_feed_validation_notices
