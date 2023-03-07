{% macro make_end_of_valid_range(timestamp_col) %}
TIMESTAMP_SUB({{ timestamp_col }}, INTERVAL 1 MICROSECOND)
{% endmacro %}

{% macro make_end_of_valid_range_date(date_col) %}
DATE_SUB({{ date_col }}, INTERVAL 1 DAY)
{% endmacro %}
