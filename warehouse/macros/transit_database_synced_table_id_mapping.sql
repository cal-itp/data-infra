{% macro transit_database_synced_table_id_mapping(
    table_a_dict,
    table_b_dict,
    shared_id_name = 'key',
    shared_name_name = 'name',
    shared_date_name = 'date') %}

    -- Takes as input two instances of a synced table from Airtable
    -- and creates a mapping table to associated the internal Airtable IDs between
    -- the two instances. Join is performed using the column listed in the
    -- name_col parameter.
    -- Table dict entries:
    -- table_name: CTE or table name to be used (one instance of the synced table)
    -- base: Name or abbreviation for the base that will be used to prefix records;
    --  ex: "ct" for the California Transit base
    -- id_col: Name of the internal Airtable ID column in this table
    -- name_col: Name of the primary field column in this table
    -- date_col: Name of the column containing the date that the table was extracted

    {% set table_a = table_a_dict.get('table_name') %}
    {% set base_a = table_a_dict.get('base') %}
    {% set table_a_id_col = table_a_dict.get('id_col', 'key') %}
    {% set table_a_name_col = table_a_dict.get('name_col', 'name') %}
    {% set table_a_date_col = table_a_dict.get('date_col', 'dt') %}
    {% set table_b = table_b_dict.get('table_name') %}
    {% set base_b = table_b_dict.get('base') %}
    {% set table_b_id_col = table_b_dict.get('id_col', 'key') %}
    {% set table_b_name_col = table_b_dict.get('name_col', 'name') %}
    {% set table_b_date_col = table_b_dict.get('date_col', 'dt') %}

   -- select distinct gets one mapping per day
   -- TODO: refactor to be more explicit about this, perhaps use the get_latest_dense_rank macro
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
