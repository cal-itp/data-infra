{{ config(materialized='table') }}

WITH calendar_dates_clean as (
    SELECT *
    FROM {{ ref('calendar_dates_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'calendar_dates',
    clean_table_name = 'calendar_dates_clean') }}

SELECT * FROM calendar_dates
