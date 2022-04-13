{{ config(materialized='table') }}

WITH agency_clean as (
    SELECT *
    FROM {{ ref('agency_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'agency',
    clean_table_name = 'agency_clean') }}

SELECT * FROM agency
