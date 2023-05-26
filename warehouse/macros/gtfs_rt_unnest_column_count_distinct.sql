{% macro gtfs_rt_unnest_column_count_distinct(table, key_col, array_col, output_column_name) %}
SELECT
    {{ key_col }},
    COUNT(DISTINCT unnested) AS {{ output_column_name }}
FROM {{ table }}
LEFT JOIN UNNEST({{ array_col }}) AS unnested
GROUP BY 1
{% endmacro %}
