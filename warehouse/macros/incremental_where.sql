{%- macro incremental_where(default_start_var, this_dt_column = 'dt', filter_dt_column = 'dt', dev_lookback_days = 7) -%}
{#- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost -#}
{#- save max timestamp in a variable instead so it can be referenced in incremental logic and still use partition elimination -#}
{#- code moved to incremental_max_date in order to have only one source of truth -#}
{{ filter_dt_column }} >= '{{ incremental_max_date(default_start_var=default_start_var, this_dt_column=this_dt_column, filter_dt_column=filter_dt_column, dev_lookback_days=dev_lookback_days) | trim }}'
{%- endmacro %}
