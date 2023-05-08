{% macro gtfs_interval_to_seconds(gtfs_interval_field) %}
-- convert a BigQuery hours to seconds interval (assumed to be from a GTFS "Time" field) to a count of seconds

EXTRACT(HOUR FROM {{ gtfs_interval_field }}) * 3600
    + EXTRACT(MINUTE FROM {{ gtfs_interval_field }}) * 60
    + EXTRACT(SECOND FROM {{ gtfs_interval_field }})

{% endmacro %}
