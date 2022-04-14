{{ config(materialized='table') }}

WITH trips_clean as (
    SELECT *
    FROM {{ ref('trips_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'trips',
    clean_table_name = 'trips_clean') }}

SELECT * FROM trips
