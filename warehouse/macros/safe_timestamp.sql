{% macro safe_timestamp(column_name) -%}
{#- Use this macro to convert and return only TIMESTAMP values when a column contains a mix of UNIX timestamp (epoch) and TIMESTAMP #}
{#- The column on the table need to be set as STRING #}
IF(SAFE_CAST({{ column_name }} AS NUMERIC) IS NOT NULL,
   TIMESTAMP_MILLIS(SAFE_CAST({{ column_name }} AS INT64)),
   SAFE_CAST({{ column_name }} AS TIMESTAMP))
{% endmacro %}
