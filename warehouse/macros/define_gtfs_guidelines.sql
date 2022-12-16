-- declare checks
{% macro static_feed_downloaded_successfully() %}
"GTFS schedule feed downloads successfully"
{% endmacro %}

{% macro no_validation_errors() %}
"No errors in MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro complete_wheelchair_accessibility_data() %}
"Includes complete wheelchair accessibility data in both stops.txt and trips.txt"
{% endmacro %}

{% macro shapes_file_present() %}
"Shapes.txt file is present"
{% endmacro %}

{% macro shapes_for_all_trips() %}
"Every trip in trips.txt has a shape_id listed"
{% endmacro %}

{% macro shapes_valid() %}
"No shapes-related errors appear in the MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro technical_contact_listed() %}
"Technical contact is listed in feed_contact_email field within the feed_info.txt file"
{% endmacro %}

{% macro no_rt_critical_validation_errors() %}
"No critical errors in the MobilityData GTFS Realtime Validator"
{% endmacro %}

{% macro trip_id_alignment() %}
"All trip_ids provided in the GTFS-rt feed exist in the GTFS Schedule feed"
{% endmacro %}

-- Remove the below 3 macros once v1 guideline checks table is deprecated
-- These like-checks ought to be be grouped alphabetically, so I swapped around the names for new pipeline

{% macro vehicle_positions_feed_present() %}
"Vehicle positions RT feed is present"
{% endmacro %}

{% macro trip_updates_feed_present() %}
"Trip updates RT feed is present"
{% endmacro %}

{% macro service_alerts_feed_present() %}
"Service alerts RT feed is present"
{% endmacro %}

-- Remove above 3 macros once v1 guideline checks table is deprecated

{% macro feed_present_vehicle_positions() %}
"Vehicle positions RT feed is present"
{% endmacro %}

{% macro feed_present_trip_updates() %}
"Trip updates RT feed is present"
{% endmacro %}

{% macro feed_present_service_alerts() %}
"Service alerts RT feed is present"
{% endmacro %}

{% macro rt_https_vehicle_positions() %}
"Vehicle positions RT feed uses HTTPS"
{% endmacro %}

{% macro rt_https_trip_updates() %}
"Trip updates RT feed uses HTTPS"
{% endmacro %}

{% macro rt_https_service_alerts() %}
"Service alerts RT feed uses HTTPS"
{% endmacro %}

{% macro pathways_valid() %}
"No pathways-related errors appear in the MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro schedule_feed_on_transitland() %}
"GTFS schedule feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro vehicle_positions_feed_on_transitland() %}
"Vehicle positions RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro trip_updates_feed_on_transitland() %}
"Trip updates RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro service_alerts_feed_on_transitland() %}
"Service alerts RT feed is listed on feed aggregator transit.land"
{% endmacro %}

{% macro include_tts() %}
"Include tts_stop_name entries in stops.txt for stop names that are pronounced incorrectly in most mobile applications"
{% endmacro %}

{% macro no_expired_services() %}
"No expired services are listed in the feed"
{% endmacro %}

{% macro no_7_day_feed_expiration() %}
"Feed will be valid for more than 7 days"
{% endmacro %}

{% macro no_30_day_feed_expiration() %}
"Feed will be valid for more than 30 days"
{% endmacro %}

{% macro passes_fares_validator() %}
"Passes Fares v2 portion of MobilityData GTFS Schedule Validator"
{% endmacro %}

{% macro lead_time() %}
"All schedule changes in the last month have provided at least 7 days of lead time"
{% endmacro %}

{% macro no_pb_error_tu() %}
"Fewer than 1% of requests to Trip updates RT feed result in a protobuf error"
{% endmacro %}

{% macro no_pb_error_sa() %}
"Fewer than 1% of requests to Service alerts RT feed result in a protobuf error"
{% endmacro %}

{% macro no_pb_error_vp() %}
"Fewer than 1% of requests to Vehicle positions RT feed result in a protobuf error"
{% endmacro %}

-- declare features
{% macro compliance_schedule() %}
"Compliance (Schedule)"
{% endmacro %}

{% macro compliance_rt() %}
"Compliance (RT)"
{% endmacro %}

{% macro accurate_accessibility_data() %}
"Accurate Accessibility Data"
{% endmacro %}

{% macro accurate_service_data() %}
"Accurate Service Data"
{% endmacro %}

{% macro technical_contact_availability() %}
"Technical Contact Availability"
{% endmacro %}

{% macro fixed_route_completeness() %}
"Fixed-Route Completeness"
{% endmacro %}

{% macro feed_aggregator_availability_schedule() %}
"Feed Aggregator Availability (Schedule)"
{% endmacro %}

{% macro feed_aggregator_availability_rt() %}
"Feed Aggregator Availability (RT)"
{% endmacro %}

{% macro best_practices_alignment_schedule() %}
"Best Practices Alignment (Schedule)"
{% endmacro %}

{% macro best_practices_alignment_rt() %}
"Best Practices Alignment (RT)"
{% endmacro %}

{% macro fare_completeness() %}
"Fare Completeness"
{% endmacro %}

{% macro up_to_dateness() %}
"Up-to-Dateness"
{% endmacro %}

-- columns
{% macro gtfs_guidelines_columns() %}
date,
calitp_itp_id,
calitp_url_number,
calitp_agency_name,
check,
status,
feature
{% endmacro %}
