{# mostly copied from dbt_utils not_null_proportion #}

{% macro test_unique_proportion(model, group_by_columns = []) %}
  {{ return(adapter.dispatch('test_unique_proportion', 'dbt_utils')(model, group_by_columns, **kwargs)) }}
{% endmacro %}

{% macro default__test_unique_proportion(model, group_by_columns) %}

{% set column_name = kwargs.get('column_name', kwargs.get('arg')) %}
{% set at_least = kwargs.get('at_least', kwargs.get('arg')) %}
{% set at_most = kwargs.get('at_most', kwargs.get('arg', 1)) %}

with validation as (
  select
    sum(case when row_number > 1 then 0 else 1 end) / cast(count(*) as numeric) as unique_proportion
  from (select
    {{column_name}}
    , row_number() over (partition by {{column_name}}) as row_number
  from {{ model }}) row_counts
),
validation_errors as (
  select
    unique_proportion
  from validation
  where unique_proportion < {{ at_least }} or unique_proportion > {{ at_most }}
)
select
  *
from validation_errors

{% endmacro %}
