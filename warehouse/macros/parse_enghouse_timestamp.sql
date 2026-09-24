{% macro parse_enghouse_timestamp(column_name) -%}
{#- Enghouse usually emits ISO-8601 timestamps with seconds ("2026-04-11T23:34:03"), but #}
{#- sometimes omits them ("2026-05-18T15:01"). BigQuery's timestamp literal grammar requires #}
{#- seconds, so SAFE_CAST silently returns NULL for the second form, this silently assumes :00 seconds' #}
COALESCE(
    SAFE_CAST({{ column_name }} AS TIMESTAMP),
    SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M', TRIM({{ column_name }}))
)
{%- endmacro %}
