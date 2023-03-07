WITH daily_notices AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
),

bad_rows AS (
    SELECT
        date,
        feed_key,
        COUNT(DISTINCT validation_validator_version) AS num_versions,
    FROM daily_notices
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT validation_validator_version) > 1
)

SELECT * FROM bad_rows
