{% macro list_of_columns(iterable_of_columns) %}
{% for col in iterable_of_columns %}
{# Only add comma if not last: https://docs.getdbt.com/tutorial/using-jinja#use-looplast-to-avoid-trailing-commas #}
{{ col }}
{% if not loop.last %}
 ,
{% endif %}
{% endfor %}
{% endmacro %}
