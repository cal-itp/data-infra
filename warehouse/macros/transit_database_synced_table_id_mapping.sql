{% macro transit_database_synced_table_id_mapping(
    table_a,
    base_a,
    table_a_id_col,
    table_a_name_col,
    table_a_date_col,
    table_b,
    base_b,
    table_b_id_col,
    table_b_name_col,
    table_b_date_col,
    shared_id_name,
    shared_name_name,
    shared_date_name) %}

   SELECT DISTINCT
        {{ base_a }}.{{ table_a_id_col }} AS {{ base_a }}_{{ shared_id_name }},
        {{ base_b }}.{{ table_b_id_col }} AS {{ base_b }}_{{ shared_id_name }},
        {{ base_a }}.{{ table_a_name_col }} AS {{ base_a }}_{{ shared_name_name }},
        {{ base_b }}.{{ table_b_name_col }} AS {{ base_b }}_{{ shared_name_name }},
        {{ base_a }}.{{ table_a_date_col }} AS {{ base_a }}_{{ shared_date_name }},
        {{ base_b }}.{{ table_b_date_col }} AS {{ base_b }}_{{ shared_date_name }},
    FROM {{ table_a }} AS {{ base_a }}
    FULL OUTER JOIN {{ table_b }} AS {{ base_b }}
        ON {{ base_a }}.{{ table_a_name_col }} = {{ base_b }}.{{ table_b_name_col }}
        AND {{ base_a }}.{{ table_a_date_col }} = {{ base_b }}.{{ table_b_date_col }}
    WHERE {{ base_a }}.{{ table_a_id_col }} IS NOT NULL AND {{ base_b }}.{{ table_b_id_col }} IS NOT NULL

{% endmacro %}
