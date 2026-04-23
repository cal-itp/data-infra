{%- macro ranged_incremental_min_date(default_lookback, data_earliest_start, lookback_unit = 'day') -%}
    {%- if is_incremental() -%}
        {# if it's an incremental run, respect the DBT_INCREMENTAL_START_DATE dbt var if set #}
        {# and otherwise use the default lookback window #}
        {%- if var('DBT_INCREMENTAL_START_DATE','') != '' -%}
            {# in quotes because this should be a date like 2026-04-01 #}
            {# never try to pull data earlier than data_earliest_start #}
            greatest(date('{{ data_earliest_start }}'), date('{{ var("DBT_INCREMENTAL_START_DATE") }}'))
        {%- else -%}
            {# never try to pull data earlier than data_earliest_start #}
            greatest(date('{{ data_earliest_start }}'), date_sub(current_date(), interval {{ default_lookback|string }} {{ lookback_unit }}))
        {%- endif -%}

    {%- else  -%}
        {# if not incremental, just set min to data start date #}
        {# in quotes because this should be a date like 2026-04-01 #}
        '{{ data_earliest_start }}'

    {%- endif -%}
{%- endmacro %}

{%- macro ranged_incremental_max_date() -%}
    {# if it's an incremental run, respect the DBT_INCREMENTAL_END_DATE dbt var if set #}
    {%- if is_incremental() and var('DBT_INCREMENTAL_END_DATE','') != '' -%}
        {# in quotes because this should be a date like 2026-04-01 #}
        '{{ var("DBT_INCREMENTAL_END_DATE") }}'
    {%- else -%}
        {# if not incremental or variable not set, just set max to today #}
        current_date()
    {%- endif -%}

{%- endmacro %}
