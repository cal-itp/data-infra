{{ config(materialized='table') }}

WITH translations_clean as (
    SELECT *
    FROM {{ ref('translations_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'translations',
    clean_table_name = 'translations_clean') }}

SELECT * FROM translations
