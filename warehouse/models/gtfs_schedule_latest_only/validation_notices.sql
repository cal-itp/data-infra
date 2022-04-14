{{ config(materialized='table') }}

WITH validation_notices_clean as (
    SELECT *
    FROM {{ ref('validation_notices_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'validation_notices',
    clean_table_name = 'validation_notices_clean') }}

SELECT * FROM validation_notices
