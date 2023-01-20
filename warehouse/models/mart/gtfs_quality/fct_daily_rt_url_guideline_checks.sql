{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__rt_feeds_present'),
        ],
    ) }}
),

fct_daily_rt_url_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'base64_url', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_rt_url_guideline_checks
