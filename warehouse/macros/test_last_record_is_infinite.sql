{% macro test_last_record_is_infinite(model, upper_bound_column, partition_by) %}

select {{ partition_by }},
       max({{ upper_bound_column }})
from {{ model }}
group by ({{ partition_by }})
having max({{ upper_bound_column }}) != CAST("2099-01-01" AS TIMESTAMP)

{% endmacro %}
