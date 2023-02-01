{% macro payments_tests_date_spine() %}
(

WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

distinct_providers AS (
    SELECT DISTINCT participant_id
    FROM payments_rides
),

min_max_dates AS (
    SELECT
        MIN(DATE(transaction_date_time_pacific)) AS min_date,
        MAX(DATE(transaction_date_time_pacific)) AS max_date
    FROM payments_rides
),

date_range AS (

    SELECT day_history
    FROM min_max_dates,
        UNNEST(
            GENERATE_DATE_ARRAY(min_max_dates.min_date, min_max_dates.max_date, INTERVAL 1 DAY)
    ) AS day_history

),

payments_tests_date_spine AS (
    SELECT
        participant_id,
        day_history
    FROM distinct_providers, date_range
)

SELECT * FROM payments_tests_date_spine

)
{% endmacro %}
