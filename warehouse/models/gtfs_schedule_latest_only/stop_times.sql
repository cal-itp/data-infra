{{ config(materialized='table') }}

WITH stop_times_clean as (
    SELECT *
    FROM {{ ref('stop_times_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'stop_times',
    clean_table_name = 'stop_times_clean') }}

SELECT * FROM stop_times
