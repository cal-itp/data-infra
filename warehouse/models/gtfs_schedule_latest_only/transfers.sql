{{ config(materialized='table') }}

WITH transfers_clean as (
    SELECT *
    FROM {{ ref('transfers_clean') }}
),
latest_only_source as (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),
{{ get_latest_schedule_data(
    latest_only_source = 'latest_only_source',
    table_name = 'transfers',
    clean_table_name = 'transfers_clean') }}

SELECT * FROM transfers
