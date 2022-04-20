{{ config(materialized='table') }}

WITH
{{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'translations',
    clean_table_name = ref('translations_clean')
    ) }}

SELECT * FROM translations
