{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

validation_codes AS (
    SELECT * FROM {{ ref('int_gtfs_guidelines_v2__schedule_validation_severities') }}
),

-- TODO: this is just schedule, add RT
validation_outcomes AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_outcomes') }}
),

validation_notices AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

fct_daily_feed_validation_notices AS (
    SELECT
        {{ dbt_utils.surrogate_key(['daily_feeds.date', 'daily_feeds.feed_key', 'codes.code']) }} AS key,
        daily_feeds.date,
        daily_feeds.feed_key,
        codes.code,
        codes.severity,
        outcomes.validation_success,
        outcomes.validation_exception,
        SUM(total_notices) AS total_notices,
    FROM fct_daily_schedule_feeds AS daily_feeds
    LEFT JOIN dim_schedule_feeds AS dim_feeds
        ON daily_feeds.feed_key = dim_feeds.key
    LEFT JOIN validation_outcomes AS outcomes
        ON dim_feeds.base64_url = outcomes.base64_url
        AND dim_feeds._valid_from = outcomes.extract_ts
    CROSS JOIN validation_codes AS codes
    LEFT JOIN validation_notices AS notices
        ON codes.code = notices.code
    GROUP BY 1, 2, 3, 4, 5, 6, 7
)

SELECT * FROM fct_daily_feed_validation_notices
