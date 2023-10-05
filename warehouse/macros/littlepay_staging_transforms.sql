-- regex to identify timestamp within a Littlepay filename
{% macro lp_filename_timestamp_regex() %}
'^([0-9]{12})_.*'
{% endmacro %}

-- regex to identify date within a Littlepay filename
{% macro lp_filename_date_regex() %}
'^([0-9]{8})[0-9]{4}_.*'
{% endmacro %}

-- use regex to actually extract timestamp from filename
{% macro extract_littlepay_filename_ts(column='extract_filename') %}
CASE
    -- check that the column actually contains this pattern; there are some invalid filenames
    WHEN REGEXP_EXTRACT({{ column }}, {{ lp_filename_timestamp_regex() }}) IS NOT NULL
        THEN TIMESTAMP(PARSE_DATETIME(
                '%Y%m%d%H%M',
                REGEXP_EXTRACT({{ column }}, {{ lp_filename_timestamp_regex() }})
                ), 'UTC')
END
{% endmacro %}

-- use regex to actually extract date from filename
{% macro extract_littlepay_filename_date(column='extract_filename') %}
CASE
    -- check that the column actually contains this pattern; there are some invalid filenames
    WHEN REGEXP_EXTRACT({{ column }}, {{ lp_filename_date_regex() }}) IS NOT NULL
        THEN PARSE_DATE(
                '%Y%m%d',
                REGEXP_EXTRACT({{ column }}, {{ lp_filename_date_regex() }})
                )
END
{% endmacro %}

{% macro qualify_dedupe_full_duplicate_lp_rows(content_hash_col = '_content_hash', file_ts_col = 'littlepay_export_ts', line_number_col = '_line_number') %}

-- remove full duplicate rows where *all* content is the same
-- get most recent instance across files and then highest-line-number instance within most recent file
QUALIFY ROW_NUMBER()
    OVER (PARTITION BY {{ content_hash_col }} ORDER BY {{ file_ts_col }} DESC, {{ line_number_col }} DESC) = 1

{% endmacro %}
