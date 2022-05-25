{% macro transit_database_two_table_join(table_a, table_a_join_col, table_a_id_col,
table_a_name_col, table_b, table_b_join_col, table_b_id_col,
table_b_name_col) %}

-- follow Airflow sandbox example for unnesting airtable data

WITH
unnested_table_a AS (
    SELECT
        T1.{{ table_a_id_col }}
        , T1.name as {{ table_a_name_col }}
        , CAST({{ table_a_join_col }} AS STRING) AS {{ table_b_id_col }}
    FROM
        {{ table_a }} T1
        , UNNEST(JSON_VALUE_ARRAY({{ table_a_join_col }})) {{ table_a_join_col }}
),
unnested_t2 AS (
    SELECT
        T2.{{ table_b_id_col }}
        , T2.name as {{ table_b_name_col }}
        , CAST({{ table2_col }} AS STRING) AS {{ table_a_id_col }}
    FROM
        {{ table2 }} T2
        , UNNEST(JSON_VALUE_ARRAY({{ table2_col }})) {{ table2_col }}
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING({{ table_a_id_col }}, {{ table_b_id_col }})
"""

{% endmacro %}
