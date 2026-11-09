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

{% macro unscaled_and_scaled_prediction_error_percentiles_by_group(table_name, iterable_of_group_columns) %}

WITH prediction_error_by_group AS (
    {{ get_percentiles_by_group(
        table_name,
        iterable_of_group_columns,
        array_col='prediction_error_by_minute_array',
        decimals=1)
    }}
),

scaled_prediction_error_by_group AS (
    {{ get_percentiles_by_group(
        table_name,
        iterable_of_group_columns,
        array_col='scaled_prediction_error_by_minute_array',
        decimals=3)
    }}
),

-- select only positive values for array (only do it on unscaled)
prediction_errors_subset AS ( -- noqa: L045
	SELECT
		{{ list_of_columns(iterable_of_group_columns) }},
	    ARRAY(
            SELECT pe FROM UNNEST(prediction_error_by_minute_array) AS pe WHERE pe > 0
        ) AS pos_prediction_error,
	    ARRAY(
            SELECT pe FROM UNNEST(prediction_error_by_minute_array) AS pe WHERE pe < 0
        ) AS neg_prediction_error,
	FROM {{ table_name }}
),

pos_prediction_errors AS (
    {{ get_percentiles_by_group(
        'prediction_errors_subset',
        iterable_of_group_columns,
        array_col='pos_prediction_error',
        decimals=1)
    }}
),

neg_prediction_errors AS (
    {{ get_percentiles_by_group(
        'prediction_errors_subset',
        iterable_of_group_columns,
        array_col='neg_prediction_error',
        decimals=1)
    }}
),

prediction_array_results AS (
    SELECT
        pe.{{ list_of_columns(iterable_of_group_columns) }},


        pe.value_array AS prediction_error_sec_array,
        pe.value_percentile_array AS prediction_error_sec_percentile_array,
        spe.value_array AS scaled_prediction_error_sec_array,

        -- there seems to be some null elements in the pos/neg ones, why? isolating this join to where data is complete hasn't made this go away
        ARRAY(
            SELECT
                COALESCE(pe, 0) AS pe
                FROM UNNEST(pos_pe.value_array) AS pe
        ) AS pos_prediction_error_sec_array,
        ARRAY(
            SELECT
                COALESCE(pe, 0) AS pe
                FROM UNNEST(neg_pe.value_array) AS pe
        ) AS neg_prediction_error_sec_array,
		-- do this because the Newmark paper plots these arrays
		-- to create the charts where smaller errors (closer to zero) are better,
		-- the larger positive errors reverse the percentiles them so that the 10th percentile has larger values
		ARRAY_REVERSE(pos_pe.value_percentile_array) AS pos_prediction_error_sec_percentile_array

    FROM prediction_error_by_group AS pe
    INNER JOIN scaled_prediction_error_by_group AS spe
        USING ({{ list_of_columns(iterable_of_group_columns) }})
    LEFT JOIN pos_prediction_errors AS pos_pe --not sure if filtering impacts rows disappearing, use left join for now
        USING ({{ list_of_columns(iterable_of_group_columns) }})
    LEFT JOIN neg_prediction_errors AS neg_pe
        USING ({{ list_of_columns(iterable_of_group_columns) }})
)

SELECT * FROM prediction_array_results

{% endmacro %}
