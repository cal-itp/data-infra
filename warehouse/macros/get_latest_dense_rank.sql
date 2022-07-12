{% macro get_latest_dense_rank(external_table, order_by, partition_by = None) %}

WITH ranked AS (
    SELECT *,
        DENSE_RANK() OVER (
            {% if partition_by %}
            PARTITION BY {{ partition_by }}
            {% endif %}
            ORDER BY {{ order_by }}) as rank
    FROM {{ external_table }}
)
SELECT * FROM ranked WHERE rank = 1

{% endmacro %}
