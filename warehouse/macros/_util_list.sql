{% macro util_list(item_list) %}
    {% for item in item_list %}
    {{ item }}
    {% if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}
