{{ config(materialized='table') }}

WITH
{{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'pathways',
    clean_table_name = ref('pathways_clean')
    ) }}

SELECT * FROM pathways
