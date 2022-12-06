{{ config(store_failures = true) }}

WITH payments_rides AS (

    SELECT *
    FROM {{ ref('payments_rides') }}

),

extract_count_date AS (

    SELECT

        COUNT(*) AS ridership_count,
        DATE(
            EXTRACT(DATE FROM transaction_date_time_pacific)
        ) AS transaction_date

    FROM payments_rides
    WHERE participant_id = 'mst'
    GROUP BY transaction_date
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (ORDER BY transaction_date)
            ) / LAG(ridership_count, 1)
            OVER (ORDER BY transaction_date)) * 100
        AS relative_difference

    FROM extract_count_date

),

test_recent_values AS (

    SELECT

        transaction_date,
        ridership_count,
        relative_difference

    FROM calculate_relative_difference
    WHERE ABS(relative_difference) > 25.0
        AND transaction_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 1 WEEK)
        AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    ORDER BY transaction_date

)

SELECT * FROM test_recent_values
