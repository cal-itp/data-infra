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

{% macro transit_database_many_to_many2(
    shared_start_date_name,
    shared_end_date_name,
    shared_current_name,
    table_a = {},
    table_b = {}
    ) %}

    -- TODO: refactor this to take individual dict inputs for each table instead of so many prefixed fields
    -- follow Airflow sandbox example for unnesting airtable data

    WITH
    unnested_table_a AS (
        SELECT
            T1.{{ table_a['unversioned_key_col'] }} AS table_a_unversioned_key
            , T1.{{ table_a['versioned_key_col'] }} AS {{ table_a['key_col_name'] }}
            , T1.{{ table_a['name_col'] }} AS {{ table_a['name_col_name'] }}
            , CAST({{ table_a['unversioned_join_col'] }} AS STRING) AS table_b_unversioned_key
            , T1.{{ table_a['start_date_col'] }} AS {{ shared_start_date_name }}
            , T1.{{ table_a['end_date_col'] }} AS {{ shared_end_date_name }}
            , T1.{{ shared_current_name }} AS {{ shared_current_name }}
        FROM
            {{ table_a['name'] }} T1
            , UNNEST({{ table_a['unversioned_join_col'] }}) {{ table_a['unversioned_join_col'] }}
    ),

    unnested_table_b AS (
        SELECT
            T2.{{ table_b['unversioned_key_col'] }} AS table_b_unversioned_key
            , T2.{{ table_b['versioned_key_col'] }} AS {{ table_b['key_col_name'] }}
            , T2.{{ table_b['name_col'] }} AS {{ table_b['name_col_name'] }}
            , CAST({{ table_b['unversioned_join_col'] }} AS STRING) AS table_a_unversioned_key
            , T2.{{ table_b['start_date_col'] }} AS {{ shared_start_date_name }}
            , T2.{{ table_b['end_date_col'] }} AS {{ shared_end_date_name }}
            , T2.{{ shared_current_name }} AS {{ shared_current_name }}
        FROM
            {{ table_b['name'] }} T2
            , UNNEST({{ table_b['unversioned_join_col'] }}) {{ table_b['unversioned_join_col'] }}
    )

    SELECT
        unnested_table_a.{{ table_a['key_col_name'] }} AS {{ table_a['key_col_name'] }},
        unnested_table_b.{{ table_b['key_col_name'] }} AS {{ table_b['key_col_name'] }},
        unnested_table_a.{{ table_a['name_col_name'] }},
        unnested_table_b.{{ table_b['name_col_name'] }},
        GREATEST(unnested_table_a.{{ shared_start_date_name }}, unnested_table_b.{{ shared_start_date_name }}) AS {{ shared_start_date_name }},
        LEAST(unnested_table_a.{{ shared_end_date_name }}, unnested_table_b.{{ shared_end_date_name }}) AS {{ shared_end_date_name }},
        (unnested_table_a.{{ shared_current_name }} AND unnested_table_b.{{ shared_current_name }}) AS {{ shared_current_name }}
    FROM unnested_table_a
    FULL OUTER JOIN unnested_table_b
        ON unnested_table_a.table_a_unversioned_key = unnested_table_b.table_a_unversioned_key
        AND unnested_table_b.table_b_unversioned_key = unnested_table_a.table_b_unversioned_key
        AND unnested_table_a.{{ shared_start_date_name }} < unnested_table_b.{{ shared_end_date_name }}
        AND unnested_table_a.{{ shared_end_date_name }} > unnested_table_b.{{ shared_start_date_name }}

{% endmacro %}
