{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__no_schedule_validation_errors'),
            ref('int_gtfs_quality__shapes_valid'),
            ref('int_gtfs_quality__technical_contact_listed'),
            ref('int_gtfs_quality__shapes_for_all_trips'),
            ref('int_gtfs_quality__complete_wheelchair_accessibility_data'),
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
