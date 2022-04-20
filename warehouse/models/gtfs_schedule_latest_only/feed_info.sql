{{ config(materialized='table') }}

WITH
{{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'feed_info',
    clean_table_name = ref('feed_info_clean')
    ) }}

SELECT * FROM feed_info
