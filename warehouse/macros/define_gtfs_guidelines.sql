-- declare checks
{% macro static_feed_downloaded_successfully() %}
"Static GTFS feed downloads successfully"
{% endmacro %}

{% macro no_validation_errors_in_last_30_days() %}
"No validation errors in last 30 days"
{% endmacro %}

{% macro complete_wheelchair_accessibility_data() %}
"Includes complete wheelchair accessibility data in both stops.txt and trips.txt"
{% endmacro %}

{% macro shapes_file_present() %}
"Shapes.txt file is present"
{% endmacro %}

-- declare features
{% macro compliant_on_the_map() %}
"Compliance"
{% endmacro %}

{% macro accurate_accessibility_data() %}
"Accurate Accessibility Data"
{% endmacro %}

{% macro accurate_service_data() %}
"Accurate Service Data"
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
