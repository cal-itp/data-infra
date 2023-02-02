{{ config(materialized='ephemeral') }}

{% set min_date_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_date = min_date_list[0] %}

{% set max_date_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_date = max_date_list[0] %}

WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

distinct_providers AS (
    SELECT DISTINCT participant_id
    FROM payments_rides
),

create_date_range AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="'" ~ min_date ~ "'",
        end_date="'" ~ max_date ~ "'"
    )
    }}
),

payments_tests_date_spine AS (
    SELECT
        participant_id,
        date_day AS day_history
    FROM distinct_providers
    CROSS JOIN create_date_range
)

SELECT * FROM payments_tests_date_spine
