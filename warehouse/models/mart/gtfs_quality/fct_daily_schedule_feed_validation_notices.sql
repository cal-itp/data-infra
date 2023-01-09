{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

validation_codes AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_validation_severities') }}
),

validation_outcomes AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_outcomes') }}
),

outcome_validator_versions AS (
    SELECT * FROM {{ ref('int_gtfs_quality__outcome_validator_versions') }}
),

validation_notices AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

fct_daily_schedule_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.surrogate_key(['daily_feeds.date',
                                    'daily_feeds.feed_key',
                                    'versions.gtfs_validator_version',
                                    'codes.code',
        ]) }} AS key,
        daily_feeds.date,
        daily_feeds.feed_key,
        versions.gtfs_validator_version,
        codes.code,
        codes.severity,
        outcomes.validation_success,
        outcomes.validation_exception,
        COALESCE(
            SUM(total_notices),
            CASE WHEN validation_success THEN 0 END
        ) AS total_notices,
    FROM fct_daily_schedule_feeds AS daily_feeds
    LEFT JOIN dim_schedule_feeds AS dim_feeds
        ON daily_feeds.feed_key = dim_feeds.key
    LEFT JOIN validation_outcomes AS outcomes
        ON dim_feeds.base64_url = outcomes.base64_url
        AND dim_feeds._valid_from = outcomes.extract_ts
    LEFT JOIN outcome_validator_versions AS versions
        ON outcomes.base64_url = versions.base64_url
        AND outcomes.extract_ts = versions.ts
    LEFT JOIN validation_codes AS codes
        ON versions.gtfs_validator_version = codes.gtfs_validator_version
    LEFT JOIN validation_notices AS notices
        ON codes.code = notices.code
        AND outcomes.base64_url = notices.base64_url
        AND outcomes.extract_ts = notices.ts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_daily_schedule_feed_validation_notices
