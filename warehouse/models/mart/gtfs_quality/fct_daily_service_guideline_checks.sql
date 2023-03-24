{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__trip_planner_schedule'),
            ref('int_gtfs_quality__trip_planner_rt'),
            ref('int_gtfs_quality__scheduled_trips_in_tu_feed'),
            ref('int_gtfs_quality__all_tu_in_vp'),
            ref('int_gtfs_quality__feed_listed_schedule'),
            ref('int_gtfs_quality__feed_listed_vp'),
            ref('int_gtfs_quality__feed_listed_tu'),
            ref('int_gtfs_quality__feed_listed_sa'),
        ],
    ) }}
),

fct_daily_service_guideline_checks AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['date', 'service_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_service_guideline_checks
