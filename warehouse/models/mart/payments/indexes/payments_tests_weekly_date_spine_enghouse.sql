{{ config(materialized='ephemeral') }}

{% set min_week_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_enghouse'), column='start_dttm', where='start_dttm IS NOT NULL', order_by = 'start_dttm', max_records = 1) %}

{% set min_week = min_week_list[0].strftime('%Y-%m-%d') if min_week_list and min_week_list[0] else (modules.datetime.date.today() - modules.datetime.timedelta(days=7)).isoformat() %}

{% set max_week_list = dbt_utils.get_column_values(table=ref('fct_payments_rides_enghouse'), column='start_dttm', where='start_dttm IS NOT NULL', order_by = 'start_dttm DESC', max_records = 1) %}

{% set max_week = max_week_list[0].strftime('%Y-%m-%d') if max_week_list and max_week_list[0] else modules.datetime.date.today().isoformat() %}

WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_enghouse') }}
),

distinct_providers AS (
    SELECT DISTINCT operator_id
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

payments_tests_weekly_date_spine_enghouse AS (
    SELECT
        operator_id,
        date_week AS week_start,
        DATE_ADD(date_week, INTERVAL 6 DAY) AS week_end
    FROM distinct_providers
    CROSS JOIN create_week_range
)

SELECT * FROM payments_tests_weekly_date_spine_enghouse
