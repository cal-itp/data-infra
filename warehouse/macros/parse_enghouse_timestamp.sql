{% macro parse_enghouse_timestamp(column_name) -%}
{#- Enghouse emits naive ISO-8601 timestamps in Pacific Time with no offset, usually with #}
{#- seconds ("2026-04-11T23:34:03") but sometimes without ("2026-05-18T15:01"). We parse #}
{#- them as DATETIME and localize to America/Los_Angeles. Values that carry a timezone #}
{#- designator will not parse as DATETIME and become NULL; the #}
{#- enghouse_timestamp_has_no_timezone test alerts us if that starts happening. #}
TIMESTAMP(
    COALESCE(
        SAFE_CAST(TRIM({{ column_name }}) AS DATETIME),
        SAFE.PARSE_DATETIME('%Y-%m-%dT%H:%M', TRIM({{ column_name }}))
    ),
    'America/Los_Angeles'
)
{%- endmacro %}
