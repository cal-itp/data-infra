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

successful_validation_outcomes AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_outcomes') }}
    WHERE validation_success
),

validation_notices AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

-- For each version of a feed, we use the first time a given version
-- of the validator was run against that feed; technically we don't
-- guarantee that the "range" will never have overlapped, for example
-- a backfill could also produce v4 validations alongside v3
first_outcome_per_version AS (
    SELECT outcomes.*, feeds.key AS feed_key
    FROM successful_validation_outcomes outcomes
    INNER JOIN dim_schedule_feeds feeds
        ON outcomes.base64_url = feeds.base64_url
        AND outcomes.extract_ts BETWEEN feeds._valid_from AND feeds._valid_to
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY feeds.key, outcomes.validation_validator_version
        ORDER BY outcomes.extract_ts
    ) = 1
),

fct_daily_schedule_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.surrogate_key(['daily_feeds.date',
                                    'daily_feeds.feed_key',
                                    'outcomes.validation_validator_version',
                                    'codes.code',
        ]) }} AS key,
        daily_feeds.date,
        daily_feeds.feed_key,
        outcomes.validation_validator_version,
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
    LEFT JOIN first_outcome_per_version AS outcomes
        ON dim_feeds.key = outcomes.feed_key
    LEFT JOIN validation_codes AS codes
        ON outcomes.validation_validator_version = codes.gtfs_validator_version
    LEFT JOIN validation_notices AS notices
        ON codes.code = notices.code
        AND outcomes.base64_url = notices.base64_url
        AND outcomes.extract_ts = notices.ts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_daily_schedule_feed_validation_notices
