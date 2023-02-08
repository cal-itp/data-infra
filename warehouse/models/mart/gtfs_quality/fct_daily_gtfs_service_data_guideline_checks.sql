{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__fixed_routes_match'),
            ref('int_gtfs_quality__demand_responsive_routes_match'),
        ],
    ) }}
),

fct_daily_gtfs_service_data_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'gtfs_service_data_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_gtfs_service_data_guideline_checks
