{% macro payments_tests_date_spine() %}
(

WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),


distinct_providers AS (
    SELECT

        DISTINCT participant_id

    FROM payments_rides
),

max_min_dates AS (
    SELECT

        MIN(DATE(transaction_date_time_pacific)) AS min_date,
        MAX(DATE(transaction_date_time_pacific)) AS max_date

    FROM payments_rides
),

date_range AS (

    SELECT
        day
    FROM max_min_dates, UNNEST(
        GENERATE_DATE_ARRAY(max_min_dates.min_date, max_min_dates.max_date, INTERVAL 1 DAY)
    ) AS day

),

payments_tests_date_spine AS (
    SELECT

        participant_id,
        day

    FROM distinct_providers, date_range
)

SELECT * FROM payments_tests_date_spine

)
{% endmacro %}
