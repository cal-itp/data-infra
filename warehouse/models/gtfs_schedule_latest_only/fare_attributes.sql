{{ config(materialized='table') }}

WITH
fare_attributes AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'fare_attributes',
    clean_table_name = ref('fare_attributes_clean')
    ) }}
)

SELECT * FROM fare_attributes
