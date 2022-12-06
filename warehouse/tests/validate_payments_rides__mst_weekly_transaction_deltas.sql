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
                    EXTRACT(WEEK FROM transaction_date_time_pacific) AS string
                ),
                2,
                '0'
            )
        ) AS yearweek

    FROM payments_rides
    WHERE participant_id = 'mst'
    GROUP BY yearweek
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (ORDER BY yearweek)
            ) / LAG(ridership_count, 1) OVER (ORDER BY yearweek)
        ) * 100
        AS relative_difference

    FROM extract_count_date
    WHERE yearweek NOT LIKE '%-00'

),

test_recent_values AS (

    SELECT

        yearweek,
        ridership_count,
        relative_difference

    FROM
        (SELECT
            yearweek,
            ridership_count,
            relative_difference,
            RANK() OVER (ORDER BY yearweek DESC) AS rank
            FROM calculate_relative_difference)
    WHERE rank != 1
        AND rank < 5
        AND ABS(relative_difference) > 25.0
    ORDER BY yearweek

)

SELECT * FROM test_recent_values
