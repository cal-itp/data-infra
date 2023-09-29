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

{% macro qualify_dedupe_lp_files(file_dt_col = 'littlepay_export_date', file_ts_col = 'littlepay_export_ts', ts_col = 'ts') %}

-- remove duplicate instances of the same file (file defined as date-level update from LP)
-- partition by file date, order by LP-defined timestamp (most recent first), and then order by our extract timestamp (most recent first)
-- use dense rank instead of row number because we need to allow all rows from a given file to be included (allow ties)
QUALIFY DENSE_RANK()
    OVER (PARTITION BY {{ file_dt_col }} ORDER BY {{ file_ts_col }} DESC, {{ ts_col }} DESC) = 1

{% endmacro %}

{% macro qualify_dedupe_lp_rows(content_hash_col = 'content_hash', file_ts_col = 'littlepay_export_ts', line_number_col = '_line_number') %}

-- remove full duplicate rows where *all* content is the same
-- get most recent instance across files and then highest-line-number instance within most recent file
QUALIFY ROW_NUMBER()
    OVER (PARTITION BY {{ content_hash_col }} ORDER BY {{ file_ts_col }} DESC, {{ line_number_col }} DESC) = 1

{% endmacro %}
