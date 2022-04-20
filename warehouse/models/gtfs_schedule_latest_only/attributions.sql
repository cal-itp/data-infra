{{ config(materialized='table') }}

WITH
{{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'attributions',
    clean_table_name = ref('attributions_clean')
 ) }}

SELECT * FROM attributions
