{% macro lp_filename_timestamp_regex() %}
'^([0-9]{12})_.*'
{% endmacro %}

{% macro lp_filename_date_regex() %}
'^([0-9]{8})_.*'
{% endmacro %}

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

{% macro extract_littlepay_filename_date(column='extract_filename') %}
CASE
    -- check that the column actually contains this pattern; there are some invalid filenames
    WHEN REGEXP_EXTRACT({{ column }}, {{ lp_filename_date_regex() }}) IS NOT NULL
        THEN TIMESTAMP(PARSE_DATE(
                '%Y%m%d',
                REGEXP_EXTRACT({{ column }}, {{ lp_filename_date_regex() }})
                ), 'UTC')
END
{% endmacro %}
