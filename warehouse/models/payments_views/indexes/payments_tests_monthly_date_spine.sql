{{ config(materialized='ephemeral') }}

{% set min_month_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific', max_records = 1) %}

{% set min_month = min_month_list[0] %}

{% set max_month_list = dbt_utils.get_column_values(table=ref('payments_rides'), column='transaction_date_pacific', order_by = 'transaction_date_pacific DESC', max_records = 1) %}

{% set max_month = max_month_list[0] %}

{{ log(min_month ~ " " ~ max_month) }}


WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

distinct_providers AS (
    SELECT DISTINCT participant_id
    FROM payments_rides
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
