{{ config(materialized='table') }}

WITH levels_clean as (
    SELECT *
    FROM {{ ref('levels_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'levels',
    clean_table_name = 'levels_clean') }}

SELECT * FROM levels