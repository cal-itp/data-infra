{{ config(materialized='table') }}

WITH frequencies_clean as (
    SELECT *
    FROM {{ ref('frequencies_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'frequencies',
    clean_table_name = 'frequencies_clean') }}

SELECT * FROM frequencies
