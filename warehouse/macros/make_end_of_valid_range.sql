{{% macro make_end_of_valid_range(timestamp_col) %}}
TIMESTAMP_SUB(timestamp col, INTERVAL 1 MICROSECOND)
{{% endmacro %}}
