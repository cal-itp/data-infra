{{ config(materialized='ephemeral') }}

{% set min_date_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_date = min_date_list[0] if min_date_list[0] else modules.datetime.date.today() - modules.datetime.timedelta(days=1) %}

{% set max_date_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_date = max_date_list[0] if max_date_list[0] else modules.datetime.date.today() %}

WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_v2') }}
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

payments_tests_daily_date_spine AS (
    SELECT
        participant_id,
        date_day AS day_history
    FROM distinct_providers
    CROSS JOIN create_date_range
)

SELECT * FROM payments_tests_daily_date_spine
