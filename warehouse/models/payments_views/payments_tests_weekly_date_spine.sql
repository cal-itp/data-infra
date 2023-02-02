{{ config(materialized='ephemeral') }}

{% set min_week_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_week = min_week_list[0] %}

{% set max_week_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_week = max_week_list[0] %}

WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

distinct_providers AS (
    SELECT DISTINCT participant_id
    FROM payments_rides
),

create_week_range AS (
    {{ dbt_utils.date_spine(
        datepart="week",
        start_date="'" ~ min_week ~ "'",
        end_date="'" ~ max_week ~ "'"
    )
    }}
),

payments_tests_weekly_date_spine AS (
    SELECT
        participant_id,
        date_week AS week_history
    FROM distinct_providers
    CROSS JOIN create_week_range
)

SELECT * FROM payments_tests_weekly_date_spine
