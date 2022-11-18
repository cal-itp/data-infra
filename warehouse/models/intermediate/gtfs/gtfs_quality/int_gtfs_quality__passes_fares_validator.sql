WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

keyed_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__keyed_parse_outcomes')}}
),

validation_fact_daily_feed_codes_fares_related AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
     WHERE code IN ('fare_transfer_rule_duration_limit_type_without_duration_limit',
                    'fare_transfer_rule_duration_limit_without_type',
                    'fare_transfer_rule_invalid_transfer_count',
                    'fare_transfer_rule_missing_transfer_count',
                    'fare_transfer_rule_with_forbidden_transfer_count',
                    'invalid_currency_amount'
                    )
),

daily_feed_fare_files AS (
    SELECT feed_key,
           COUNT(*) AS ct_files
      FROM keyed_parse_outcomes
     WHERE parse_success
       AND gtfs_filename IN ('fare_leg_rules',
                             'rider_categories',
                             'fare_containers',
                             'fare_products',
                             'fare_transfer_rules'
                             )
       AND feed_key IS NOT null
     GROUP BY 1
),

validation_notices_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(total_notices) as validation_notices
    FROM validation_fact_daily_feed_codes_fares_related
    GROUP BY feed_key, date
),

int_gtfs_quality__passes_fares_validator AS (
    SELECT
        idx.date,
        idx.feed_key,
        {{ passes_fares_validator() }} AS check,
        {{ fare_completeness() }} AS feature,
        CASE
            WHEN files.feed_key IS null THEN "N/A"
            WHEN notices.validation_notices = 0 THEN "PASS"
            WHEN notices.validation_notices > 0 THEN "FAIL"
        END AS status
    FROM feed_guideline_index idx
    LEFT JOIN validation_notices_by_day notices
        ON idx.feed_key = notices.feed_key
            AND idx.date = notices.date
    LEFT JOIN daily_feed_fare_files files
        ON idx.feed_key = files.feed_key
)

SELECT * FROM int_gtfs_quality__passes_fares_validator
