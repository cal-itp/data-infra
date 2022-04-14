{{ config(materialized='table') }}

WITH shapes_clean as (
    SELECT *
    FROM {{ ref('shapes_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'shapes',
    clean_table_name = 'shapes_clean') }}

SELECT * FROM shapes
