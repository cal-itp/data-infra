{% macro gtfs_rt_dt_where() -%}

{%- if is_incremental() -%}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_dt = dates[0] %}
    {%- if target.name.startswith('prod') -%}
        {% set start_dt = max_dt %}
    {%- else -%}
        {# Never look back more than 7 days #}
        {% set start_dt = [max_dt, (modules.datetime.date.today() - modules.datetime.timedelta(days=7))] | max %}
    {%- endif -%}
{%- else -%}
    {%- if target.name.startswith('prod') -%}
        {% set start_dt = var('PROD_GTFS_RT_START') %}
    {%- else -%}
        {% set start_dt = modules.datetime.date.today() - modules.datetime.timedelta(days=7) %}
    {%- endif -%}
{%- endif -%}
dt >= '{{ start_dt }}'
{% endmacro %}
