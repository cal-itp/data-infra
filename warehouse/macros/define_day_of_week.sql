-- Transit is typically Weekday / Saturday / Sunday service
-- Big Query has Sunday as 1 (https://cloud.google.com/bigquery/docs/reference/standard-sql/date_functions#extract)
{% macro generate_day_type(date_column) %}
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 1 THEN "Sunday"
        WHEN EXTRACT(DAYOFWEEK FROM {{ date_column }}) = 7 THEN "Saturday"
        ELSE 'Weekday'
    END

{% endmacro %}

{% macro generate_time_of_day_column(hour_column) %}
    CASE
        WHEN {{ hour_column }} < 4 OR ( {{ hour_column }} >= 24 AND {{ hour_column }} < 28 ) THEN "owl"
        WHEN {{ hour_column }} < 7 OR ( {{ hour_column }} >= 28 AND {{ hour_column }} < 31 ) THEN "early_am"
        WHEN {{ hour_column }} < 10 OR ( {{ hour_column }} >= 31 AND {{ hour_column }} < 34 ) THEN "am_peak"
        WHEN {{ hour_column }} < 15 OR ( {{ hour_column }} >= 34 AND {{ hour_column }} < 39 ) THEN "midday"
        WHEN {{ hour_column }} < 20 OR ( {{ hour_column }} >= 39 AND {{ hour_column }} < 44 ) THEN "pm_peak"
        WHEN {{ hour_column }} < 24 OR ( {{ hour_column }} >= 44 AND {{ hour_column }} < 48 ) THEN "evening"
        ELSE NULL
    END

{% endmacro %}

{% macro generate_time_of_day_hours(time_of_day_column) %}
    CASE
        -- hours 0-3; 20-23
        WHEN {{ time_of_day_column }} = "owl" OR {{ time_of_day_column }} = "evening" THEN 4
        -- hours 4-6; 7-9
        WHEN {{ time_of_day_column }}  = "early_am" OR {{ time_of_day_column }}  = "am_peak" THEN 3
        -- hours 10-14; 15-19
        WHEN {{ time_of_day_column }}  = "midday" OR {{ time_of_day_column }}  = "pm_peak" THEN 5
        ELSE NULL
    END

{% endmacro %}
