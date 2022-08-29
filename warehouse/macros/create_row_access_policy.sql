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
  {% if not filter_column and not filter_value %}
  1 = 1
  {% else %}
  {{ filter_column }} = '{{ filter_value }}'
  {% endif %}
)
{% endmacro %}
