{# Fails for any row where a column disagrees with the corresponding column in another model,
   joined on join_columns.

   Rows where either side is null are ignored: this tests that the two sources agree where both
   have a value, not that both sources are populated.

   `field` defaults to the name of the column being tested.
#}

{% test matches_column_in_model(model, column_name, to, join_columns, field=None) %}

{% set other_column = field or column_name %}

WITH this_model AS (
    SELECT * FROM {{ model }}
),

other_model AS (
    SELECT * FROM {{ to }}
)

SELECT
    {% for join_column in join_columns %}{{ join_column }},
    {% endfor %}this_model.{{ column_name }} AS this_value,
    other_model.{{ other_column }} AS other_value
FROM this_model
INNER JOIN other_model
    USING ({{ join_columns | join(', ') }})
WHERE this_model.{{ column_name }} IS NOT NULL
    AND other_model.{{ other_column }} IS NOT NULL
    AND this_model.{{ column_name }} != other_model.{{ other_column }}

{% endtest %}
