-- see: https://gtfs.org/schedule/reference/#field-types
-- "time is measured from 'noon minus 12h' of the service day (effectively midnight except for days on which daylight savings time changes occur)"
-- so this macro takes a service date & time zone and returns the "midnight" that times are defined against
{% macro gtfs_noon_minus_twelve_hours(service_date, timezone) %}
TIMESTAMP_SUB(
    TIMESTAMP(
        DATETIME({{ service_date }}, TIME(12,0,0)),
        {{ timezone }}
    ),
    INTERVAL 12 HOUR)
{% endmacro %}
