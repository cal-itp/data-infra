{{ config(materialized='table') }}

WITH calendar_clean as (
    SELECT *
    FROM {{ ref('calendar_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'calendar',
    clean_table_name = 'calendar_clean') }}

SELECT * FROM calendar
