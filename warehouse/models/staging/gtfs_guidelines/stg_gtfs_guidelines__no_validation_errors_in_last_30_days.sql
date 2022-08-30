WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ no_validation_errors_in_last_30_days() }}
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

validation_errors_in_last_30_days_check AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        check,
        feature,
        SUM(validation_errors)
            OVER (
                PARTITION BY
                    calitp_itp_id,
                    calitp_url_number
                ORDER BY date
                ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
        ) AS errors_last_30_days
    FROM feed_guideline_index
    LEFT JOIN validation_errors_by_day USING (feed_key, date)
),

validation_errors_in_last_30_days_idx AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        check,
        CASE
            WHEN errors_last_30_days > 0 THEN "FAIL"
            WHEN errors_last_30_days = 0 THEN "PASS"
        END AS status,
        feature
    FROM validation_errors_in_last_30_days_check
)

SELECT * FROM validation_errors_in_last_30_days_idx
