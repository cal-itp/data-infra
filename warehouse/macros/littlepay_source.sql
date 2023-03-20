{% macro littlepay_source(src, tbl) %}

(
    SELECT
        *,
        -- have to parse the filename since there are no other timestamps seemingly
        PARSE_DATETIME(
            '%Y%m%d%H%M',
            REGEXP_EXTRACT(extract_filename, '([0-9]{12})_.*')
        ) AS littlepay_export_ts
    FROM {{ source(src, tbl) }}
)
{% endmacro %}
