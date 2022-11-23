{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

code_descriptions AS (
    SELECT * FROM {{ ref('stg_gtfs_quality__schedule_validation_code_descriptions') }}
),

validation_outcomes AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_outcomes') }}
),

validation_notices AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

observed_validator_versions AS (
    SELECT DISTINCT
        dt,
        gtfs_validator_version,
    FROM validation_notices
),

fct_daily_schedule_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.surrogate_key(['daily_feeds.date', 'daily_feeds.feed_key', 'codes.code']) }} AS key,
        daily_feeds.date,
        daily_feeds.feed_key,
        -- TODO: at some point, these codes will be versioned by validator version
        codes.code,
        codes.severity,
        outcomes.validation_success,
        outcomes.validation_exception,
        versions.gtfs_validator_version,
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
    LEFT JOIN observed_validator_versions AS versions
        ON daily_feeds.date = versions.dt
    LEFT JOIN code_descriptions AS codes
        ON versions.gtfs_validator_version = codes.gtfs_validator_version
    LEFT JOIN validation_notices AS notices
        ON codes.code = notices.code
        AND outcomes.extract_ts = notices.ts
    WHERE daily_feeds.date < CURRENT_DATE()
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_daily_schedule_feed_validation_notices
