{{ config(materialized='ephemeral') }}

{% set min_month_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_month = min_month_list[0] if min_month_list[0] else modules.datetime.date.today() - modules.datetime.timedelta(days=30) %}

{% set max_month_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_v2'), column='transaction_date_pacific', where='transaction_date_pacific IS NOT NULL', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_month = max_month_list[0] if max_month_list[0] else modules.datetime.date.today() %}

{{ log(min_month ~ " " ~ max_month) }}


WITH fct_payments_rides_v2 AS (
    SELECT * FROM {{ ref('fct_payments_rides_v2') }}
),

distinct_providers AS (
    SELECT DISTINCT participant_id
    FROM fct_payments_rides_v2
),

create_month_range AS (
    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="'" ~ min_month ~ "'",
        end_date="'" ~ max_month ~ "'"
    )
    }}
),

clean_month_range AS (

    SELECT
        CAST(DATE_TRUNC(date_month, month) as date) AS month_start
    FROM create_month_range

),

payments_tests_monthly_date_spine AS (
    SELECT
        participant_id,
        month_start,
        LAST_DAY(month_start) AS month_end
    FROM distinct_providers
    CROSS JOIN clean_month_range
)

SELECT * FROM payments_tests_monthly_date_spine
