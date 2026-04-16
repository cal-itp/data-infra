{%- macro ranged_incremental_min_date(default_lookback, data_earliest_start, lookback_unit = 'day') -%}

    {# first, set min and max dates for the range #}
    {%- if is_incremental() -%}

        {%- if var('DBT_INCREMENTAL_START_DATE','') != '' -%}
            {%- set min_dt = var('DBT_INCREMENTAL_START_DATE') %}
            '{{ min_dt }}'
        {%- else -%}
            {%- set min_dt = 'date_sub(current_date(), interval ' + default_lookback|string + ' ' + lookback_unit + ')' %}
            {{ min_dt }}
        {%- endif -%}

    {%- else  -%}
        {# if not incremental, just set min to dataset start #}
        {%- set min_dt = data_earliest_start %}
        '{{ min_dt }}'

    {%- endif -%}



{%- endmacro %}

{%- macro ranged_incremental_max_date() -%}

    {%- if is_incremental() -%}

        {%- if var('DBT_INCREMENTAL_END_DATE','') != '' -%}
            {%- set max_dt = var('DBT_INCREMENTAL_END_DATE') %}
            '{{ max_dt }}'
        {%- else -%}
            {%- set max_dt = 'current_date()' %}
            {{ max_dt }}
        {%- endif -%}

    {%- else  -%}
        {# if not incremental, just set max to today #}
        {%- set max_dt = 'current_date()' %}
        {{ max_dt }}
    {%- endif -%}

{%- endmacro %}
