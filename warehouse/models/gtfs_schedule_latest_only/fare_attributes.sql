{{ config(materialized='table') }}

WITH fare_attributes_clean as (
    SELECT *
    FROM {{ ref('fare_attributes_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'fare_attributes',
    clean_table_name = 'fare_attributes_clean') }}

SELECT * FROM fare_attributes
