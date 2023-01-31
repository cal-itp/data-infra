{% macro get_latest_schedule_data(table_name, clean_table_name) %}

-- Use dim_schedule_feeds to identify current rows.
-- Clustering on feed_key should make these types
-- of operations more performant; clustering is done
-- in the make_schedule_file_dimension_from_dim_schedule_feeds
-- macro.

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
