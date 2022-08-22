{% macro create_row_access_policy(filter_column,filter_value, principals) %}
create or replace row access policy
    {{ this.schema }}_{{ this.identifier }}_{{ filter_column }}_{{ dbt_utils.slugify(filter_value) }}
on
    {{ this }}
grant to (
  {% for principal in principals %}
  '{{ principal }}'
  {% if not loop.last %} , {% endif %}
  {% endfor %}
)
filter using (
  {{ filter_column }} = '{{ filter_value }}'
)
{% endmacro %}
