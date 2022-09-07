WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ no_validation_errors() }}
),

validation_fact_daily_feed_codes AS (
    SELECT * FROM {{ ref('validation_fact_daily_feed_codes') }}
),

validation_dim_codes AS (
    SELECT * FROM {{ ref('validation_dim_codes') }}
),

validation_errors_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(n_notices) as validation_errors
    FROM validation_fact_daily_feed_codes
    LEFT JOIN validation_dim_codes USING(code)
    WHERE severity = "ERROR"
    GROUP BY feed_key, date
),

validation_errors_daily_check AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        check,
        feature,
        CASE
            WHEN validation_errors > 0 THEN "FAIL"
            WHEN validation_errors = 0 THEN "PASS"
        END AS status,
    FROM feed_guideline_index
    LEFT JOIN validation_errors_by_day USING (feed_key, date)
)

SELECT * FROM validation_errors_daily_check
