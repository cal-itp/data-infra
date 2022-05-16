{% macro get_latest_external_data(external_table_name, columns) %}

WITH ranked AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY {{ columns }}) as rank
    FROM {{ external_table_name }}
),
SELECT * FROM ranked WHERE rank = 1

{% endmacro %}
