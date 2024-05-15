WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ passes_fares_validator() }}
),

files AS (
    SELECT * FROM {{ ref('fct_schedule_feed_files') }}
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

feed_has_fares AS (
    SELECT feed_key,
           LOGICAL_OR(gtfs_filename IN ('fare_leg_rules',
                             'rider_categories',
                             'fare_containers',
                             'fare_products',
                             'fare_transfer_rules'
                             )) AS has_fares
      FROM files
     WHERE parse_success
       AND feed_key IS NOT NULL
     GROUP BY feed_key
),

tot_validation_notices AS (
    SELECT
        feed_key,
        SUM(total_notices) as validation_notices
    FROM validation_fact_daily_feed_codes_fares_related
    GROUP BY feed_key
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM validation_fact_daily_feed_codes_fares_related
),

int_gtfs_quality__passes_fares_validator AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        validation_notices,
        has_fares,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN has_fares AND validation_notices = 0 THEN {{ guidelines_pass_status() }}
                        WHEN tot_validation_notices.feed_key IS NULL OR NOT has_fares THEN {{ guidelines_na_check_status() }}
                        WHEN has_fares AND validation_notices > 0 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_has_fares
        ON idx.schedule_feed_key = feed_has_fares.feed_key
    LEFT JOIN tot_validation_notices
      ON idx.schedule_feed_key = tot_validation_notices.feed_key
)

SELECT * FROM int_gtfs_quality__passes_fares_validator
