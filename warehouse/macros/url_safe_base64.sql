-- since BigQuery doesn't have a URL-safe default base64 encoding, use macros to define our own
-- based on the docs here: https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators#to_base64

{% macro to_url_safe_base64(column) %}
TO_BASE64(CAST(REPLACE(REPLACE({{ column }},'-','+'),'_','/') AS BYTES))
{% endmacro %}

{% macro from_url_safe_base64(column) %}
CAST(FROM_BASE64(REPLACE(REPLACE({{ column }}, '-', '+'), '_', '/')) AS STRING)
{% endmacro %}
