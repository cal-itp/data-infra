{{ config(materialized='table') }}

WITH
stops AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'stops',
    clean_table_name = ref('stops_clean')
    ) }}
)

SELECT * FROM stops
