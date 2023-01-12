{{ config(materialized='table') }}

WITH
agency AS (
    {{ get_latest_schedule_data(
        latest_only_source = ref('calitp_feeds'),
        table_name = 'agency',
        clean_table_name = ref('agency_clean')
        ) }}
)

SELECT * FROM agency
