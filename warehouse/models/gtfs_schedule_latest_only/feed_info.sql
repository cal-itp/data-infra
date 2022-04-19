{{ config(materialized='table') }}

WITH feed_info_clean as (
    SELECT *
    FROM {{ ref('feed_info_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'feed_info',
    clean_table_name = 'feed_info_clean') }}

SELECT * FROM feed_info