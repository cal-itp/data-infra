{% macro get_percentiles_by_group(table_name, iterable_of_group_columns, array_col) %}
WITH unfiltered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], 1) AS p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], 1) AS p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], 1) AS p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], 1) AS p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], 1) AS p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], 1) AS p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], 1) AS p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], 1) AS p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], 1) AS p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], 1) AS p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], 1) AS p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], 1) AS p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], 1) AS p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value
    GROUP BY {{ list_of_columns(iterable_of_group_columns) }}
),

unfiltered_aggregated_table2 AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},
        [p5, p10, p20, p25, p30, p40, p50, p60, p70, p75, p80, p90, p95] AS value_array,
        [5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95] AS value_percentile_array
    FROM unfiltered_aggregated_table
),

positive_filtered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], 1) AS p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], 1) AS p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], 1) AS p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], 1) AS p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], 1) AS p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], 1) AS p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], 1) AS p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], 1) AS p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], 1) AS p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], 1) AS p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], 1) AS p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], 1) AS p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], 1) AS p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value WHERE array_value >= 0
    GROUP BY {{ list_of_columns(iterable_of_group_columns) }}
),

positive_filtered_aggregated_table2 AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},
        [p5, p10, p20, p25, p30, p40, p50, p60, p70, p75, p80, p90, p95] AS pos_value_array,
        [5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95] AS pos_value_percentile_array
    FROM positive_filtered_aggregated_table
),

negative_filtered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], 1) AS p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], 1) AS p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], 1) AS p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], 1) AS p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], 1) AS p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], 1) AS p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], 1) AS p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], 1) AS p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], 1) AS p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], 1) AS p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], 1) AS p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], 1) AS p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], 1) AS p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value WHERE array_value < 0
    GROUP BY {{ list_of_columns(iterable_of_group_columns) }}
),

negative_filtered_aggregated_table2 AS (
    SELECT
        {{ list_of_columns(iterable_of_group_columns) }},
        [p5, p10, p20, p25, p30, p40, p50, p60, p70, p75, p80, p90, p95] AS neg_value_array,
        [5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95] AS neg_value_percentile_array
    FROM negative_filtered_aggregated_table
),

full_aggregated_table AS (
    SELECT *
    FROM unfiltered_aggregated_table2
    INNER JOIN positive_filtered_aggregated_table2 USING ( {{ list_of_columns(iterable_of_group_columns) }} )
    INNER JOIN negative_filtered_aggregated_table2 USING ( {{ list_of_columns(iterable_of_group_columns) }} )
)

SELECT * FROM full_aggregated_table
{% endmacro %}
