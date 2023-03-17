-- TODO: this will replace int_gtfs_quality__guideline_checks once ready
-- description for this table got too long, don't persist to BQ
{{ config(materialized='table', persist_docs={"relation": false, "columns": true}) }}


WITH unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__schedule_download_success'),
            ref('int_gtfs_quality__feed_aggregator'),
            ref('int_gtfs_quality__trip_id_alignment'),
            ref('int_gtfs_quality__scheduled_trips_in_tu_feed'),
            ref('int_gtfs_quality__trip_planners'),
            ref('int_gtfs_quality__no_schedule_validation_errors'),
            ref('int_gtfs_quality__shapes_file_present'),
            ref('int_gtfs_quality__complete_wheelchair_accessibility_data'),
            ref('int_gtfs_quality__shapes_for_all_trips'),
            ref('int_gtfs_quality__include_tts'),
            ref('int_gtfs_quality__shapes_valid'),
            ref('int_gtfs_quality__pathways_valid'),
            ref('int_gtfs_quality__technical_contact_listed'),
            ref('int_gtfs_quality__rt_feeds_present'),
            ref('int_gtfs_quality__rt_https'),
            ref('int_gtfs_quality__no_rt_validation_errors'),
            ref('int_gtfs_quality__rt_protobuf_error'),
            ref('int_gtfs_quality__rt_20sec_vp')
        ],
    ) }}
),

int_gtfs_quality__guideline_checks_long_new_index AS (
    SELECT *
    FROM unioned
)

SELECT * FROM int_gtfs_quality__guideline_checks_long_new_index
