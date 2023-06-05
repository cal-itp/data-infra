{% macro incremental_where(default_start_var, this_dt_column = 'dt', filter_dt_column = 'dt', dev_lookback_days = 7) -%}

{%- if is_incremental() -%}
    {% if var('INCREMENTAL_MAX_DT') %}
        {% set max_dt = var('INCREMENTAL_MAX_DT') %}
    {% else %}
        -- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
        -- save max timestamp in a variable instead so it can be referenced in incremental logic and still use partition elimination
        {% set dates = dbt_utils.get_column_values(table=this, column=this_dt_column, order_by = this_dt_column + ' DESC', max_records = 1) %}
        {% set max_dt = dates[0] %}
    {% endif %}
    {%- if target.name.startswith('prod') or not dev_lookback_days -%}
        {% set start_dt = max_dt %}
    {%- else -%}
        {% set start_dt = [max_dt, (modules.datetime.date.today() - modules.datetime.timedelta(days=dev_lookback_days))] | max %}
    {%- endif -%}
{%- else -%}
    {%- if target.name.startswith('prod') or not dev_lookback_days -%}
        {% set start_dt = var(default_start_var) %}
    {%- else -%}
        {% set start_dt = modules.datetime.date.today() - modules.datetime.timedelta(days=dev_lookback_days) %}
    {%- endif -%}
{%- endif -%}
{{ filter_dt_column }} >= '{{ start_dt }}'
{% endmacro %}
