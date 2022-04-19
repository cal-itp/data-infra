{{ config(materialized='table') }}

WITH pathways_clean as (
    SELECT *
    FROM {{ ref('pathways_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'pathways',
    clean_table_name = 'pathways_clean') }}

SELECT * FROM pathways
