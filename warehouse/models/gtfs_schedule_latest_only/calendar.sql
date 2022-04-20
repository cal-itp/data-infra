{{ config(materialized='table') }}

WITH
calendar AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'calendar',
    clean_table_name = ref('calendar_clean')
    ) }}
)

SELECT * FROM calendar
