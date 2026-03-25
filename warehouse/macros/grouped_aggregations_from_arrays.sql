{% macro get_percentiles_by_group(table_name, iterable_of_group_columns, array_col, decimals) %}

WITH table_expanded AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], {{ decimals }} ) AS p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], {{ decimals }}) AS p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], {{ decimals }}) AS p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], {{ decimals }}) AS p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], {{ decimals }}) AS p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], {{ decimals }}) AS p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], {{ decimals }}) AS p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], {{ decimals }}) AS p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], {{ decimals }}) AS p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], {{ decimals }}) AS p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], {{ decimals }}) AS p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], {{ decimals }}) AS p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], {{ decimals }}) AS p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value
    GROUP BY {{ list_of_columns(iterable_of_group_columns) }}
),

results AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},
        [p5, p10, p20, p25, p30, p40, p50, p60, p70, p75, p80, p90, p95] AS value_array,
        [5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95] AS value_percentile_array
    FROM table_expanded
)

SELECT * FROM results
{% endmacro %}
