{% macro trim_make_empty_string_null(column_name) %}

CASE
    WHEN TRIM({{ column_name }}) = ""
        THEN NULL
    ELSE TRIM({{ column_name }})
END AS {{ column_name }}

{% endmacro %}
