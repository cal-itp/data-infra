{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__no_schedule_validation_errors'),
            ref('int_gtfs_quality__shapes_valid'),
            ref('int_gtfs_quality__shapes_file_present'),
            ref('int_gtfs_quality__technical_contact_listed'),
            ref('int_gtfs_quality__shapes_for_all_trips'),
            ref('int_gtfs_quality__include_tts'),
            ref('int_gtfs_quality__pathways_valid'),
            ref('int_gtfs_quality__complete_wheelchair_accessibility_data'),
            ref('int_gtfs_quality__passes_fares_validator'),
            ref('int_gtfs_quality__no_7_day_feed_expiration'),
            ref('int_gtfs_quality__no_30_day_feed_expiration'),
            ref('int_gtfs_quality__no_expired_services'),
            ref('int_gtfs_quality__persistent_ids_schedule'),
        ],
    ) }}
),

fct_daily_schedule_feed_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'feed_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_schedule_feed_guideline_checks
