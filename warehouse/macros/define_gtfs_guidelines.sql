-- declare checks
{% macro static_feed_downloaded_successfully() %}
"Static GTFS feed downloads successfully"
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
"All trip_ids provided in the GTFS-rt feed exist in the GTFS data"
{% endmacro %}

{% macro vehicle_positions_feed_present() %}
"Vehicle positions RT feed is present"
{% endmacro %}

{% macro trip_updates_feed_present() %}
"Trip updates RT feed is present"
{% endmacro %}

{% macro service_alerts_feed_present() %}
"Service alerts RT feed is present"
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

-- declare features
{% macro compliance() %}
"Compliance"
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

{% macro feed_aggregator_availability() %}
"Feed Aggregator Availability"
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
