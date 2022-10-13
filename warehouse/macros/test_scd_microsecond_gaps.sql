{% macro test_range_gaps_are_microseconds(model, lower_bound_column, upper_bound_column, partition_by) %}

select {{ partition_by }},
       {{ lower_bound_column }},
       {{ upper_bound_column }},
       TIMESTAMP_DIFF(lead({{ lower_bound_column }}) over (partition by {{ partition_by }} order by {{ lower_bound_column }}), {{ upper_bound_column }}, MICROSECOND) as diff
from {{ model }}
qualify diff > 1

{% endmacro %}
