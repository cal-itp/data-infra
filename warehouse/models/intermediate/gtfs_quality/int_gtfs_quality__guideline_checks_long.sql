-- TODO: this will replace int_gtfs_quality__guideline_checks once ready
-- description for this table got too long, don't persist to BQ
{{ config(materialized='table', persist_docs={"relation": false, "columns": true}) }}


WITH idx AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
),

unioned AS (
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
            ref('int_gtfs_quality__rt_20sec_vp'),
            ref('int_gtfs_quality__no_stale_vehicle_positions'),
            ref('int_gtfs_quality__rt_20sec_tu'),
            ref('int_gtfs_quality__no_stale_trip_updates'),
            ref('int_gtfs_quality__no_stale_service_alerts'),
            ref('int_gtfs_quality__modification_date_present_rt'),
            ref('int_gtfs_quality__contact_on_website'),
            ref('int_gtfs_quality__fixed_routes_match'),
            ref('int_gtfs_quality__demand_responsive_routes_match'),
            ref('int_gtfs_quality__data_license'),
            ref('int_gtfs_quality__authentication_acceptable'),
            ref('int_gtfs_quality__no_expired_services'),
            ref('int_gtfs_quality__no_30_day_feed_expiration'),
            ref('int_gtfs_quality__no_7_day_feed_expiration'),
            ref('int_gtfs_quality__passes_fares_validator'),
            ref('int_gtfs_quality__persistent_ids_schedule'),
            ref('int_gtfs_quality__stable_url'),
            ref('int_gtfs_quality__link_to_dataset_on_website'),
            ref('int_gtfs_quality__shapes_accurate'),
            ref('int_gtfs_quality__all_tu_in_vp'),
            ref('int_gtfs_quality__modification_date_present'),
            ref('int_gtfs_quality__grading_scheme_v1'),
            ref('int_gtfs_quality__feed_listed'),
            ref('int_gtfs_quality__lead_time'),
            ref('int_gtfs_quality__wheelchair_accessible_trips'),
            ref('int_gtfs_quality__wheelchair_boarding_stops')
        ],
        include = ['date', 'key', 'check', 'status']
    ) }}
),

int_gtfs_quality__guideline_checks_long AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['unioned.key', 'date', 'check']) }} AS key,
        unioned.* EXCEPT(key),
        unioned.key AS assessed_entity_key,
        idx.* EXCEPT(status, date, key, check)
    FROM unioned
    LEFT JOIN idx
    USING (date, key, check)
)

SELECT * FROM int_gtfs_quality__guideline_checks_long
