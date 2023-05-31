{% macro transit_database_many_to_many_versioned(
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
        -- this correlated cross join drops rows where table a has no table b records listed
        -- if we wanted to keep all rows, we could convert this to a left join
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
        -- this correlated cross join drops rows where table b has no table a records listed
        -- if we wanted to keep all rows, we could convert this to a left join
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
    -- this inner join drops rows where one of the tables has foreign keys but the other does not
    -- one example case is if one table is versioned/historical and the other is current-only,
    -- if a record in the historical table is deleted the current-only table will no longer have the relationships
    -- and the historical table will have "dangling" references
    -- this inner join drops such rows
    -- in future we could consider instead keeping all rows from both tables
    -- so that every row is guaranteed to be present whether or not it had relationships to the other table
    INNER JOIN unnested_table_b
        ON unnested_table_a.table_a_unversioned_key = unnested_table_b.table_a_unversioned_key
        AND unnested_table_b.table_b_unversioned_key = unnested_table_a.table_b_unversioned_key
        AND unnested_table_a.{{ shared_start_date_name }} < unnested_table_b.{{ shared_end_date_name }}
        AND unnested_table_a.{{ shared_end_date_name }} > unnested_table_b.{{ shared_start_date_name }}

{% endmacro %}
