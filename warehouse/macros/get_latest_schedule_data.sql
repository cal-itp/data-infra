{% macro get_latest_schedule_data(table_name) %}

-- select rows from table_name
-- where _is_current is true (i.e., from the latest batch)
-- and non-public rows are excluded

WITH {{ table_name }}_latest AS (
    SELECT * FROM {{ table_name }}
    WHERE _is_current
)
SELECT * FROM {{ table_name }}_latest
{% endmacro %}
