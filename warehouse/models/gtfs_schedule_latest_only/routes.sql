{{ config(materialized='table') }}

WITH routes_clean as (
    SELECT *
    FROM {{ ref('routes_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'routes',
    clean_table_name = 'routes_clean') }}

SELECT * FROM routes
