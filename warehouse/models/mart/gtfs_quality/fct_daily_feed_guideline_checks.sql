{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_guidelines_v2__no_schedule_validation_errors'),
            ref('int_gtfs_guidelines_v2__shapes_valid'),
        ],
    ) }}
),

fct_daily_feed_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'feed_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_feed_guideline_checks
