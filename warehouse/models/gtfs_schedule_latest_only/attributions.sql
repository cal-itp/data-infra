{{ config(materialized='table') }}

WITH attributions_clean as (
    SELECT *
    FROM {{ ref('attributions_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'attributions',
    clean_table_name = 'attributions_clean') }}

SELECT * FROM attributions
