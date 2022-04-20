{{ config(materialized='table') }}

WITH
routes AS (
    {{ get_latest_schedule_data(
    latest_only_source = ref('calitp_feeds'),
    table_name = 'routes',
    clean_table_name = ref('routes_clean')
    ) }}
)

SELECT * FROM routes
