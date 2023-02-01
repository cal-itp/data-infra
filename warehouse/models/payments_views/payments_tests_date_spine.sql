{{ config(materialized='ephemeral') }}

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

create_date_range AS (
        {{ dbt_date.get_base_dates(start_date="2022-01-01", end_date="2022-02-01", datepart="day") }}
),

payments_tests_date_spine AS (
    SELECT
        participant_id,
        date_day
    FROM distinct_providers
    CROSS JOIN create_date_range
)

SELECT * FROM payments_tests_date_spine
