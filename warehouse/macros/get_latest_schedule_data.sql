{% macro get_latest_schedule_data(table_name, clean_table_name) %}

-- select rows from table_name
-- where _is_current is true (i.e., from the latest batch)
-- and non-public rows are excluded

WITH {{ clean_table_name }}_latest AS (
    SELECT * FROM {{ table_name }} t
    WHERE EXISTS (
        SELECT 1
        FROM {{ ref('dim_schedule_feeds') }} s
        WHERE s._is_current AND t.feed_key = s.key
    )
)

SELECT * FROM {{ clean_table_name }}_latest
{% endmacro %}
