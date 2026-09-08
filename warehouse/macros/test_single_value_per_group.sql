{# Fails for any group that has more than one distinct value of the tested column.

   Use this to guard an ANY_VALUE() (or similar arbitrary pick) downstream: if every group has at
   most one value, the pick is deterministic.

   Nulls are ignored, because COUNT(DISTINCT) skips them the same way BigQuery's ANY_VALUE does,
   so a group mixing nulls with a single non-null value passes.
#}

{% test single_value_per_group(model, column_name, group_by_columns) %}

SELECT
    {{ group_by_columns | join(', ') }},
    COUNT(DISTINCT {{ column_name }}) AS num_distinct_values
FROM {{ model }}
GROUP BY {{ group_by_columns | join(', ') }}
HAVING COUNT(DISTINCT {{ column_name }}) > 1

{% endtest %}
