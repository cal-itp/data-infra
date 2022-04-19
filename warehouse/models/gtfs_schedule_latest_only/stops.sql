{{ config(materialized='table') }}

WITH stops_clean as (
    SELECT *
    FROM {{ ref('stops_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'stops',
    clean_table_name = 'stops_clean') }}

SELECT * FROM stops
