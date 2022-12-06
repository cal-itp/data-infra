{{ config(store_failures = true) }}

WITH payments_rides AS (

    SELECT *
    FROM {{ ref('payments_rides') }}

),

extract_count_date AS (

    SELECT

        COUNT(*) AS ridership_count,
        CONCAT(CAST(EXTRACT(YEAR FROM transaction_date_time_pacific) AS string),
            '-',
            LPAD(
                CAST(
                    EXTRACT(MONTH FROM transaction_date_time_pacific) AS string
                ),
                2,
                '0'
            )
        ) AS yearmonth

    FROM payments_rides
    WHERE participant_id = 'mst'
    GROUP BY yearmonth
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (ORDER BY yearmonth)
            ) / LAG(ridership_count, 1) OVER (ORDER BY yearmonth)
        ) * 100
        AS relative_difference

    FROM extract_count_date

),

test_recent_values AS (

    SELECT

        yearmonth,
        ridership_count,
        relative_difference

    FROM
        (SELECT
            yearmonth,
            ridership_count,
            relative_difference,
            RANK() OVER (ORDER BY yearmonth DESC) AS rank
            FROM calculate_relative_difference)
    WHERE rank != 1
        AND rank < 5
        AND ABS(relative_difference) > 25.0
    ORDER BY yearmonth

)

SELECT * FROM test_recent_values
