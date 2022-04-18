{% macro scd_join(tbl_a, tbl_b, using_cols, created_col="calitp_extracted_at",
    deleted_col="calitp_deleted_at", join_type="JOIN",
    sel_left_cols=None,
    sel_right_cols=None) %}

    {% set left_cols %}
    {% if sel_left_cols==None %}
    T1.* EXCEPT({{ created_col }}, {{ deleted_col }})
    {% else %}
    {{ list_of_columns(sel_left_cols) }}
    {% endif %}
    {% endset %}

    {% set right_cols %}
    {% if sel_right_cols==None %}
    T2.* EXCEPT({{ created_col }}, {{ deleted_col }})
    {% else %}
    {{ list_of_columns(sel_right_cols) }}
    {% endif %}
    {% endset %}

    -- SLOWLY CHANGING DIMENSION JOIN


    SELECT
        {{ left_cols }}
        , {{ right_cols }}
        , GREATEST(T1.{{ created_col }}, T2.{{ created_col }}) AS {{ created_col }}
        , LEAST(T1.{{ deleted_col }}, T2.{{ deleted_col }}) AS {{ deleted_col }}
    FROM {{ tbl_a }} T1
    {{ join_type }} {{ tbl_b }} T2
        USING ({{ list_of_columns(using_cols) }})
    WHERE
        T1.{{ created_col }} < T2.{{ deleted_col }}
        AND T2.{{ created_col }} < T1.{{ deleted_col }}


{% endmacro %}
