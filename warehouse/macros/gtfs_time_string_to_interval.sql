{% macro gtfs_time_string_to_interval(gtfs_time_field) %}
-- convert a GTFS "Time" string to a BQ interval type
-- INTERVAL type allows us to handle times past midnight (ex. 26:30:30)
-- see: https://gtfs.org/schedule/reference/#field-types for how GTFS defines a "Time"

CASE
    WHEN REGEXP_CONTAINS({{ gtfs_time_field }}, "^[0-9]+:[0-5][0-9]:[0-5][0-9]$") THEN CAST({{ gtfs_time_field }} AS INTERVAL)
END

{% endmacro %}
