{# See the below link for a full explanation of this macro, but briefly it namespaces non-prod environments via a schema prefix #}
{# https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-schemas#how-does-dbt-generate-a-models-schema-name #}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if not custom_schema_name -%}
        {{ default_schema }}
    {%- elif target.name.startswith('prod') or target.name.startswith('staging') -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
