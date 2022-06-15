{% macro get_latest_external_data(external_table_name, order_by) %}

WITH ranked AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY {{ order_by }}) as rank
    FROM {{ external_table_name }}
)
SELECT * FROM ranked WHERE rank = 1

{% endmacro %}
