{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__schedule_download_success'),
        ],
    ) }}
),

fct_daily_schedule_url_guideline_checks AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['date', 'base64_url', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_schedule_url_guideline_checks
