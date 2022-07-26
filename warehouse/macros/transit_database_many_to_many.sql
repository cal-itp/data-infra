{% macro transit_database_many_to_many(
    table_a,
    table_a_join_col,
    table_a_key_col,
    table_a_key_col_name,
    table_a_name_col,
    table_a_name_col_name,
    table_a_date_col,
    table_b,
    table_b_join_col,
    table_b_key_col,
    table_b_key_col_name,
    table_b_name_col,
    table_b_name_col_name,
    table_b_date_col,
    shared_date_name) %}

    -- TODO: refactor this to take individual dict inputs for each table instead of so many prefixed fields

    -- follow Airflow sandbox example for unnesting airtable data

    WITH
    unnested_table_a AS (
        SELECT
            T1.{{ table_a_key_col }} AS {{ table_a_key_col_name }}
            , T1.{{ table_a_name_col }} AS {{ table_a_name_col_name }}
            , CAST({{ table_a_join_col }} AS STRING) AS {{ table_b_key_col_name }}
            , T1.{{ table_a_date_col }} AS {{ shared_date_name }}
        FROM
            {{ table_a }} T1
            , UNNEST({{ table_a_join_col }}) {{ table_a_join_col }}
    ),
    unnested_table_b AS (
        SELECT
            T2.{{ table_b_key_col }} AS {{ table_b_key_col_name }}
            , T2.{{ table_b_name_col }} AS {{ table_b_name_col_name }}
            , CAST({{ table_b_join_col }} AS STRING) AS {{ table_a_key_col_name }}
            , T2.{{ table_a_date_col }} AS {{ shared_date_name }}
        FROM
            {{ table_b }} T2
            , UNNEST({{ table_b_join_col }}) {{ table_b_join_col }}
    )

    SELECT *
    FROM unnested_table_a
    FULL OUTER JOIN unnested_table_b USING({{ table_a_key_col_name }}, {{ table_b_key_col_name }}, {{ shared_date_name }})

{% endmacro %}
