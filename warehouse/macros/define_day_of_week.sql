-- Transit is typically Weekday / Saturday / Sunday service
-- Big Query has Sunday as 1 (https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#extract)
{% macro generate_day_type(date_column) %}
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 1 THEN "Sunday"
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 7 THEN "Saturday"
        ELSE 'Weekday'
    END

{% endmacro %}
