{{ config(materialized='table') }}

WITH
{{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'transfers',
    clean_table_name = ref('transfers_clean')
    ) }}

SELECT * FROM transfers
