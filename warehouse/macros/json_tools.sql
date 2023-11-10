{% macro _as_helper(alias, prefix = '', no_alias = false) %}
    {%- if no_alias == false -%}
        AS {{ prefix ~ '_' if prefix else '' }}{{ alias | lower | replace('.', '_') }}
    {%- endif -%}
{% endmacro %}

{% macro json_extract_column(
    col_name,
    json_path,
    alias = null,
    no_alias = false,
    is_array = false
) -%}
    {{ 'JSON_VALUE_ARRAY' if is_array else 'JSON_VALUE' }}(
        {{ col_name }},
        '$.{{ json_path }}'
    ){{ _as_helper(alias | default(json_path), col_name, no_alias) }}
{%- endmacro %}

{% macro json_extract_flattened_column(
    col_name,
    json_path,
    delimiter = ';',
    alias = null,
    no_alias = false
) -%}
    ARRAY_TO_STRING(
        {{ json_extract_column(col_name, json_path, is_array = true, no_alias = true) }},
        '{{ delimiter }}'
    ){{ _as_helper(alias | default(json_path), col_name, no_alias) }}
{%- endmacro %}
