{{ config(materialized='table') }}

WITH
outcomes_notices AS (
    SELECT
        EXTRACT(DATE FROM outcomes.extract_ts) as extract_date,
        outcomes.base64_url,
        notices.error_message_validation_rule_error_id AS code,
        ARRAY_AGG(DISTINCT notices.gtfs_validator_version IGNORE NULLS) AS gtfs_validator_versions,
        SUM(ARRAY_LENGTH(notices.occurrence_list)) AS total_notices
    FROM {{ ref('int_gtfs_quality__rt_validation_outcomes') }} AS outcomes
    INNER JOIN {{ ref('int_gtfs_quality__rt_validation_notices') }} AS notices
        ON outcomes.extract_ts = notices.ts
        AND outcomes.base64_url = notices.base64_url
    GROUP BY 1, 2, 3
),

outcomes_statistics AS (
    SELECT
        EXTRACT(DATE FROM outcomes.extract_ts) as extract_date,
        outcomes.base64_url,
        COUNT(DISTINCT outcomes.extract_ts) AS validated_extracts,
        COUNTIF(outcomes.validation_success) AS validation_successes,
        COUNT(outcomes.validation_exception) AS validation_exceptions
    FROM {{ ref('int_gtfs_quality__rt_validation_outcomes') }} AS outcomes
    GROUP BY 1, 2
),

daily_feeds_codes AS (
    SELECT
        daily_feeds.date,
        daily_feeds.base64_url,
        codes.code,
        codes.description,
        codes.is_critical
    FROM {{ ref('fct_daily_rt_feed_files') }} AS daily_feeds
    CROSS JOIN {{ ref('stg_gtfs_quality__rt_validation_code_descriptions') }} AS codes
),

daily_feeds_statistics AS (
    SELECT
        daily_feeds.date,
        daily_feeds.base64_url,
        SUM(daily_feeds.parse_success_file_count) / COUNT(daily_feeds.key) AS parsed_files,
    FROM {{ ref('fct_daily_rt_feed_files') }} AS daily_feeds
    GROUP BY 1, 2
)

-- This table reports on each entry in the daily GTFS-RT feeds table.
-- For each feed, on each day, create a row for each code in the codes table,
-- each of which contains validation error with its description and error level.
-- For each feed/day/code, retrieve outcomes and notices, then report on
-- the total number of extractions, successes, exceptions, occurrences of
-- that specific code, and the GTFS-RT validator version used.
-- If a code does not appear for a feed on a day, total_notices will be 0.
-- If there a feed was not validated on a day, total_notices will be NULL.
SELECT
    daily_feeds_codes.date,
    daily_feeds_codes.base64_url,
    daily_feeds_codes.code,
    daily_feeds_codes.description,
    daily_feeds_codes.is_critical,
    ARRAY_AGG(DISTINCT (SELECT * FROM UNNEST(outcomes_notices.gtfs_validator_versions)) IGNORE NULLS) AS gtfs_validator_versions,
    SUM(daily_feeds_statistics.parsed_files) AS parsed_files,
    SUM(outcomes_statistics.validated_extracts) AS validated_extracts,
    SUM(outcomes_statistics.validation_successes) AS validation_successes,
    SUM(outcomes_statistics.validation_exceptions) AS validation_exceptions,
    COALESCE(SUM(outcomes_notices.total_notices), IF(SUM(outcomes_statistics.validation_successes) > 0, 0, NULL)) AS total_notices
FROM daily_feeds_codes
LEFT JOIN daily_feeds_statistics
    ON daily_feeds_statistics.date = daily_feeds_codes.date
    AND daily_feeds_statistics.base64_url = daily_feeds_codes.base64_url
LEFT JOIN outcomes_statistics
    ON outcomes_statistics.base64_url = daily_feeds_codes.base64_url
    AND outcomes_statistics.extract_date = daily_feeds_codes.date
LEFT JOIN outcomes_notices
    ON daily_feeds_codes.base64_url = outcomes_notices.base64_url
    AND daily_feeds_codes.date = outcomes_notices.extract_date
    AND daily_feeds_codes.code = outcomes_notices.code
GROUP BY 1, 2, 3, 4, 5
