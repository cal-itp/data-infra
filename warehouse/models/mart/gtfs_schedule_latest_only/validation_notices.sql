{{ config(materialized='table') }}

WITH
validation_notices AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'validation_notices',
    clean_table_name = ref('validation_notices_clean')
    ) }}
)

SELECT * FROM validation_notices
