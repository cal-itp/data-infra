{{ config(materialized='table') }}

WITH
calendar_dates AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'calendar_dates',
    clean_table_name = ref('calendar_dates_clean')
    ) }}
)

SELECT * FROM calendar_dates
