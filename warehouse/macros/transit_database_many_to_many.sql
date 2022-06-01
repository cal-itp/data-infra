{% macro transit_database_many_to_many(
    table_a,
    table_a_join_col,
    table_a_id_col,
    table_a_name_col,
    table_b,
    table_b_join_col,
    table_b_id_col,
    table_b_name_col) %}

    -- follow Airflow sandbox example for unnesting airtable data

    WITH
    unnested_table_a AS (
        SELECT
            T1.{{ table_a_id_col }}
            , T1.{{ table_a_name_col }}
            , CAST({{ table_a_join_col }} AS STRING) AS {{ table_b_id_col }}
        FROM
            {{ table_a }} T1
            , UNNEST({{ table_a_join_col }}) {{ table_a_join_col }}
    ),
    unnested_table_b AS (
        SELECT
            T2.{{ table_b_id_col }}
            , T2.{{ table_b_name_col }}
            , CAST({{ table_b_join_col }} AS STRING) AS {{ table_a_id_col }}
        FROM
            {{ table_b }} T2
            , UNNEST({{ table_b_join_col }}) {{ table_b_join_col }}
    )

    SELECT *
    FROM unnested_table_a
    FULL OUTER JOIN unnested_table_b USING({{ table_a_id_col }}, {{ table_b_id_col }})

{% endmacro %}
