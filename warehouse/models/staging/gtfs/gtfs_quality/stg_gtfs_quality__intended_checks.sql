{{ config(materialized='ephemeral') }}
WITH stg_gtfs_quality__intended_checks AS (
    SELECT {{ static_feed_downloaded_successfully() }} AS check, {{ compliance_schedule() }} AS feature, {{ schedule_url() }} AS entity
    UNION ALL
    SELECT {{ no_validation_errors() }}, {{ compliance_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ shapes_file_present() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ complete_wheelchair_accessibility_data() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ shapes_for_all_trips() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ include_tts() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ shapes_valid() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ pathways_valid() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ technical_contact_listed() }}, {{ technical_contact_availability() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ no_expired_services() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ no_rt_validation_errors() }}, {{ compliance_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ trip_id_alignment() }}, {{ fixed_route_completeness() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ feed_present_vehicle_positions() }}, {{ compliance_rt() }}, {{ rt_url() }}
    UNION ALL
    SELECT {{ feed_present_trip_updates() }}, {{ compliance_rt() }}, {{ rt_url() }}
    UNION ALL
    SELECT {{ feed_present_service_alerts() }}, {{ compliance_rt() }}, {{ rt_url() }}
    UNION ALL
    SELECT {{ rt_https_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ rt_https_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ rt_https_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_pb_error_tu() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_pb_error_vp() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_pb_error_sa() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_7_day_feed_expiration() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ no_30_day_feed_expiration() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ passes_fares_validator() }}, {{ fare_completeness() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ rt_20sec_vp() }}, {{ accurate_service_data() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ rt_20sec_tu() }}, {{ accurate_service_data() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ persistent_ids_schedule() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ lead_time() }}, {{ up_to_dateness() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ no_stale_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_stale_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ no_stale_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ modification_date_present() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ schedule_feed_on_transitland() }}, {{ feed_aggregator_availability_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ vehicle_positions_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ trip_updates_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ service_alerts_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ schedule_feed_on_mobility_database() }}, {{ feed_aggregator_availability_schedule() }}, {{ schedule_feed() }}
    UNION ALL
    SELECT {{ vehicle_positions_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ trip_updates_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ service_alerts_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ modification_date_present_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ modification_date_present_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ modification_date_present_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    UNION ALL
    SELECT {{ persistent_ids_vp() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    -- UNION ALL
    -- SELECT {{ persistent_ids_tu() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}
    -- UNION ALL
    -- SELECT {{ persistent_ids_sa() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed() }}

    -- MANUAL CHECKS
    UNION ALL
    SELECT {{ organization_has_contact_info() }}, {{ technical_contact_availability() }}, {{ organization() }}
)

SELECT * FROM stg_gtfs_quality__intended_checks
