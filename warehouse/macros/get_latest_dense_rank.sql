{% macro get_latest_dense_rank(external_table, order_by, partition_by = None) %}

WITH ranked AS (
    SELECT *,
        DENSE_RANK() OVER (
            {% if partition_by %}
            PARTITION BY {{ partition_by }}
            {% endif %}
            ORDER BY {{ order_by }}) as rank,
        -- TODO: this is probably a bit fragile, but lets us fake historical Airtable data
        MIN({{ order_by.replace(' ASC','').replace(' DESC','') }}) OVER () AS universal_first_val
    FROM {{ external_table }}
    QUALIFY rank = 1
)
SELECT * FROM ranked

{% endmacro %}
