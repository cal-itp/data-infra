{% macro util_dedupe_by_freq(table_name, all_columns, dedupe_key) %}
-- deduplicate; uses a hash to have deterministic response -- keeps most common value if available
WITH hashed AS (
    SELECT
        {{ util_list(all_columns) }},
        {{ dbt_utils.surrogate_key(all_columns) }} AS key
    FROM {{ table_name }}
),

group_dupes AS (
    SELECT
        {{ util_list(all_columns) }},
        key,
        COUNT(*) AS ct
    FROM hashed
    GROUP BY {{ util_list(all_columns) }}, key
),

dedupe AS (
    {{ get_latest_dense_rank('group_dupes', util_list(["key", "ct"]), util_list(dedupe_key)) }}
)

SELECT
    {{ util_list(all_columns) }}
FROM dedupe


{% endmacro %}
