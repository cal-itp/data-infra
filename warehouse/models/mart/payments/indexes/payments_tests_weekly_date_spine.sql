{{ config(materialized='ephemeral') }}

{% set min_week_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_week = min_week_list[0] if min_week_list[0] else modules.datetime.date.today() - modules.datetime.timedelta(days=7) %}

{% set max_week_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_week = max_week_list[0] if max_week_list[0] else modules.datetime.date.today() %}

WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_v2') }}
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
        date_week AS week_start,
        DATE_ADD(date_week, INTERVAL 6 DAY) AS week_end
    FROM distinct_providers
    CROSS JOIN create_week_range
)

SELECT * FROM payments_tests_weekly_date_spine
