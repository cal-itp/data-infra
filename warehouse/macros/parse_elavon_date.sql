{% macro parse_elavon_date(column_name) %}

CASE
    WHEN LENGTH({{ column_name }}) < 8
        THEN PARSE_DATE('%m%d%Y',  CONCAT(0, {{ column_name }}))
    ELSE PARSE_DATE('%m%d%Y',  {{ column_name }})
END

{% endmacro %}
