-- Transit is typically Weekday / Saturday / Sunday service
-- Big Query has Sunday as 1 (https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#extract)
{% macro generate_day_type(date_column) %}
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 1 THEN "Sunday"
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 7 THEN "Saturday"
        ELSE 'Weekday'
    END

{% endmacro %}

{% macro generate_time_of_day_hours(time_of_day_column) %}
    CASE
        -- hours 0-3; 20-23
        WHEN {{ time_of_day_column }} = "Owl" OR {{ time_of_day_column }} = "Evening" THEN 4
        -- hours 4-6; 7-9
        WHEN {{ time_of_day_column }}  = "Early AM" OR {{ time_of_day_column }}  = "AM Peak" THEN 3
        -- hours 10-14; 15-19
        WHEN {{ time_of_day_column }}  = "Midday" OR {{ time_of_day_column }}  = "PM Peak" THEN 5
        ELSE NULL
    END

{% endmacro %}
