{% macro littlepay_source(src, tbl) %}

(
    SELECT
        *,
        -- have to parse the filename since there are no other timestamps seemingly
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts
    FROM {{ source(src, tbl) }}
)
{% endmacro %}
