{# Fails for any raw Enghouse timestamp string that carries a timezone designator ("Z" or a
   UTC offset like "-08:00" / "+0000").

   parse_enghouse_timestamp assumes Enghouse sends naive Pacific Time timestamps. If Enghouse
   starts annotating timestamps with a timezone, those values will parse to NULL and our Pacific
   Time assumption needs revisiting, so this test alerts us when that happens.

   Attach it to the parsed column of a stg_enghouse__<table> model; it inspects the raw string
   column in the matching external_enghouse.<table> source. Pass source_column when the staging
   column was renamed from the raw one.
#}

{% test enghouse_timestamp_has_no_timezone(model, column_name, source_column=none) %}

{%- set source_table = model.identifier | replace('stg_enghouse__', '') -%}
{%- set source_column = source_column or column_name -%}

SELECT
    agency,
    dt,
    _line_number,
    {{ source_column }} AS raw_value
FROM {{ source('external_enghouse', source_table) }}
WHERE REGEXP_CONTAINS(TRIM({{ source_column }}), r'(?i)(Z|[+-]\d{2}:?\d{2})$')

{% endtest %}
