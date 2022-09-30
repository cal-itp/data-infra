{% macro make_end_of_valid_range(timestamp_col) %}
TIMESTAMP_SUB({{ timestamp_col }}, INTERVAL 1 MICROSECOND)
{% endmacro %}
