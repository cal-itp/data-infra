{% macro get_percentiles_by_group(table_name, iterable_of_columns, array_col) %}

WITH unfiltered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_columns) }},

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
    GROUP BY {{ list_of_columns(iterable_of_columns) }}
),

positive_filtered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], 1) AS pos_p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], 1) AS pos_p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], 1) AS pos_p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], 1) AS pos_p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], 1) AS pos_p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], 1) AS pos_p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], 1) AS pos_p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], 1) AS pos_p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], 1) AS pos_p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], 1) AS pos_p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], 1) AS pos_p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], 1) AS pos_p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], 1) AS pos_p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value WHERE array_value >= 0
    GROUP BY {{ list_of_columns(iterable_of_columns) }}
),

negative_filtered_aggregated_table AS (
    SELECT
        {{ list_of_columns(iterable_of_columns) }},

        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(5)], 1) AS neg_p5,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(10)], 1) AS neg_p10,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(20)], 1) AS neg_p20,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(25)], 1) AS neg_p25,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(30)], 1) AS neg_p30,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(40)], 1) AS neg_p40,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(50)], 1) AS neg_p50,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(60)], 1) AS neg_p60,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(70)], 1) AS neg_p70,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(75)], 1) AS neg_p75,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(80)], 1) AS neg_p80,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(90)], 1) AS neg_p90,
        ROUND(APPROX_QUANTILES(array_value, 100)[OFFSET(95)], 1) AS neg_p95,

    FROM {{ table_name }}
    LEFT JOIN UNNEST( {{ array_col }} ) AS array_value WHERE array_value < 0
    GROUP BY {{ list_of_columns(iterable_of_columns) }}
),

full_aggregated_table AS (
    SELECT *
    FROM unfiltered_aggregated_table
    INNER JOIN positive_filtered_aggregated_table USING ( {{ list_of_columns(iterable_of_columns) }} )
    INNER JOIN negative_filtered_aggregated_table USING ( {{ list_of_columns(iterable_of_columns) }} )
)

SELECT * FROM full_aggregated_table
{% endmacro %}
