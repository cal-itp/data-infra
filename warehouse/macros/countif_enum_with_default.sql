{% macro countif_enum_with_default(column_name, value_to_check, default_value) %}
COUNTIF(COALESCE({{ column_name }}, {{ default_value }}) = {{ value_to_check }})
{% endmacro %}
