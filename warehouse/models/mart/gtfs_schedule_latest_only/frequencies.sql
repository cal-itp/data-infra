{{ config(materialized='table') }}

WITH
frequencies AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'frequencies',
    clean_table_name = ref('frequencies_clean')
    ) }}
)

SELECT * FROM frequencies
