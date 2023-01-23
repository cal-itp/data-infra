{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__all_tu_in_vp'),
        ],
    ) }}
),

fct_daily_service_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'service_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_service_guideline_checks
