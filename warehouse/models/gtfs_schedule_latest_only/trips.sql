{{ config(materialized='table') }}

WITH
trips AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'trips',
    clean_table_name = ref('trips_clean')
    ) }}
)

SELECT * FROM trips
