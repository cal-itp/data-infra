-- noqa: disable=AL03
{{ config(materialized='ephemeral') }}

WITH stg_gtfs_quality__intended_checks AS (
    SELECT {{ static_feed_downloaded_successfully() }} AS check, {{ compliance_schedule() }} AS feature, {{ schedule_url() }} AS entity, false AS is_manual, 1 AS reports_order
    UNION ALL
    SELECT {{ no_validation_errors() }}, {{ compliance_schedule() }}, {{ schedule_feed() }}, false, 2
    UNION ALL
    SELECT {{ shapes_file_present() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ complete_wheelchair_accessibility_data() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ wheelchair_accessible_trips() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}, false, 0
    UNION ALL
    SELECT {{ wheelchair_boarding_stops() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}, false, 1
    UNION ALL
    SELECT {{ shapes_for_all_trips() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ include_tts() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}, false, 2
    UNION ALL
    SELECT {{ shapes_valid() }}, {{ accurate_service_data() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ pathways_valid() }}, {{ accurate_accessibility_data() }}, {{ schedule_feed() }}, false, 3
    UNION ALL
    SELECT {{ technical_contact_listed() }}, {{ technical_contact_availability() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ no_expired_services() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ no_rt_validation_errors_vp() }}, {{ compliance_rt() }}, {{ rt_feed_vp() }}, false, 6
    UNION ALL
    SELECT {{ no_rt_validation_errors_tu() }}, {{ compliance_rt() }}, {{ rt_feed_tu() }}, false, 7
    UNION ALL
    SELECT {{ no_rt_validation_errors_sa() }}, {{ compliance_rt() }}, {{ rt_feed_sa() }}, false, 8
    UNION ALL
    SELECT {{ trip_id_alignment() }}, {{ fixed_route_completeness() }}, {{ rt_feed() }}, false, null
    UNION ALL
    SELECT {{ feed_present_vehicle_positions() }}, {{ compliance_rt() }}, {{ rt_url_vp() }}, false, 3
    UNION ALL
    SELECT {{ feed_present_trip_updates() }}, {{ compliance_rt() }}, {{ rt_url_tu() }}, false, 4
    UNION ALL
    SELECT {{ feed_present_service_alerts() }}, {{ compliance_rt() }}, {{ rt_url_sa() }}, false, 5
    UNION ALL
    SELECT {{ rt_https_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_url_tu() }}, false, null
    UNION ALL
    SELECT {{ rt_https_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_url_vp() }}, false, null
    UNION ALL
    SELECT {{ rt_https_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_url_sa() }}, false, null
    UNION ALL
    SELECT {{ no_pb_error_tu() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_tu() }}, false, null
    UNION ALL
    SELECT {{ no_pb_error_vp() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_vp() }}, false, null
    UNION ALL
    SELECT {{ no_pb_error_sa() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_sa() }}, false, null
    UNION ALL
    SELECT {{ no_7_day_feed_expiration() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ no_30_day_feed_expiration() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ passes_fares_validator() }}, {{ fare_completeness() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ rt_20sec_vp() }}, {{ accurate_service_data() }}, {{ rt_feed_vp() }}, false, null
    UNION ALL
    SELECT {{ rt_20sec_tu() }}, {{ accurate_service_data() }}, {{ rt_feed_tu() }}, false, null
    UNION ALL
    SELECT {{ persistent_ids_schedule() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ lead_time() }}, {{ up_to_dateness() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ no_stale_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_vp() }}, false, null
    UNION ALL
    SELECT {{ no_stale_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_tu() }}, false, null
    UNION ALL
    SELECT {{ no_stale_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_sa() }}, false, null
    UNION ALL
    SELECT {{ modification_date_present() }}, {{ best_practices_alignment_schedule() }}, {{ schedule_feed() }}, false, null
    UNION ALL
    SELECT {{ schedule_feed_on_transitland() }}, {{ feed_aggregator_availability_schedule() }}, {{ schedule_url() }}, false, null
    UNION ALL
    SELECT {{ vehicle_positions_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_vp() }}, false, null
    UNION ALL
    SELECT {{ trip_updates_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_tu() }}, false, null
    UNION ALL
    SELECT {{ service_alerts_feed_on_transitland() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_sa() }}, false, null
    UNION ALL
    SELECT {{ schedule_feed_on_mobility_database() }}, {{ feed_aggregator_availability_schedule() }}, {{ schedule_url() }}, false, null
    UNION ALL
    SELECT {{ vehicle_positions_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_vp() }}, false, null
    UNION ALL
    SELECT {{ trip_updates_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_tu() }}, false, null
    UNION ALL
    SELECT {{ service_alerts_feed_on_mobility_database() }}, {{ feed_aggregator_availability_rt() }}, {{ rt_url_sa() }}, false, null
    UNION ALL
    SELECT {{ modification_date_present_service_alerts() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_sa() }}, false, null
    UNION ALL
    SELECT {{ modification_date_present_vehicle_positions() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_vp() }}, false, null
    UNION ALL
    SELECT {{ modification_date_present_trip_updates() }}, {{ best_practices_alignment_rt() }}, {{ rt_feed_tu() }}, false, null
    UNION ALL
    SELECT {{ scheduled_trips_in_tu_feed() }}, {{ fixed_route_completeness() }}, {{ service() }}, false, null
    UNION ALL
    SELECT {{ all_tu_in_vp() }}, {{ fixed_route_completeness() }}, {{ service() }}, false, null
    UNION ALL
    SELECT {{ feed_listed_schedule() }}, {{ compliance_schedule() }}, {{ service() }}, false, 0
    UNION ALL
    SELECT {{ feed_listed_vp() }}, {{ compliance_rt() }}, {{ service() }}, false, 0
    UNION ALL
    SELECT {{ feed_listed_tu() }}, {{ compliance_rt() }}, {{ service() }}, false, 1
    UNION ALL
    SELECT {{ feed_listed_sa() }}, {{ compliance_rt() }}, {{ service() }}, false, 2
    -- MANUAL CHECKS
    UNION ALL
    SELECT {{ organization_has_contact_info() }}, {{ technical_contact_availability() }}, {{ organization() }}, true, null
    UNION ALL
    SELECT {{ shapes_accurate() }}, {{ accurate_service_data() }}, {{ gtfs_dataset_schedule() }}, true, null
    UNION ALL
    SELECT {{ data_license_schedule() }}, {{ compliance_schedule() }}, {{ gtfs_dataset_schedule() }}, true, 4
    UNION ALL
    SELECT {{ data_license_vp() }}, {{ compliance_rt() }}, {{ gtfs_dataset_vp() }}, true, 12
    UNION ALL
    SELECT {{ data_license_tu() }}, {{ compliance_rt() }}, {{ gtfs_dataset_tu() }}, true, 13
    UNION ALL
    SELECT {{ data_license_sa() }}, {{ compliance_rt() }}, {{ gtfs_dataset_sa() }}, true, 14
    UNION ALL
    SELECT {{ authentication_acceptable_schedule() }}, {{ availability_on_website() }}, {{ gtfs_dataset_schedule() }}, true, null
    UNION ALL
    SELECT {{ authentication_acceptable_vp() }}, {{ availability_on_website() }}, {{ gtfs_dataset_vp() }}, true, null
    UNION ALL
    SELECT {{ authentication_acceptable_tu() }}, {{ availability_on_website() }}, {{ gtfs_dataset_tu() }}, true, null
    UNION ALL
    SELECT {{ authentication_acceptable_sa() }}, {{ availability_on_website() }}, {{ gtfs_dataset_sa() }}, true, null
    UNION ALL
    SELECT {{ stable_url_schedule() }}, {{ compliance_schedule() }}, {{ gtfs_dataset_schedule() }}, true, 3
    UNION ALL
    SELECT {{ stable_url_vp() }}, {{ compliance_rt() }}, {{ gtfs_dataset_vp() }}, true, 9
    UNION ALL
    SELECT {{ stable_url_tu() }}, {{ compliance_rt() }}, {{ gtfs_dataset_tu() }}, true, 10
    UNION ALL
    SELECT {{ stable_url_sa() }}, {{ compliance_rt() }}, {{ gtfs_dataset_sa() }}, true, 11
    UNION ALL
    SELECT {{ grading_scheme_v1() }}, {{ accurate_service_data() }}, {{ gtfs_dataset_schedule() }}, true, null
    UNION ALL
    SELECT {{ link_to_dataset_on_website_schedule() }}, {{ availability_on_website() }}, {{ gtfs_dataset_schedule() }}, true, null
    UNION ALL
    SELECT {{ link_to_dataset_on_website_vp() }}, {{ availability_on_website() }}, {{ gtfs_dataset_vp() }}, true, null
    UNION ALL
    SELECT {{ link_to_dataset_on_website_tu() }}, {{ availability_on_website() }}, {{ gtfs_dataset_tu() }}, true, null
    UNION ALL
    SELECT {{ link_to_dataset_on_website_sa() }}, {{ availability_on_website() }}, {{ gtfs_dataset_sa() }}, true, null
    UNION ALL
    SELECT {{ trip_planner_schedule() }}, {{ compliance_schedule() }}, {{ service() }}, true, 5
    UNION ALL
    SELECT {{ trip_planner_rt() }}, {{ compliance_rt() }}, {{ service() }}, true, 15
    UNION ALL
    SELECT {{ fixed_routes_match() }}, {{ fixed_route_completeness() }}, {{ gtfs_service_data_schedule() }}, true, null
    UNION ALL
    SELECT {{ demand_responsive_routes_match() }}, {{ demand_responsive_completeness() }}, {{ gtfs_service_data_schedule() }}, true, null
)

SELECT * FROM stg_gtfs_quality__intended_checks
