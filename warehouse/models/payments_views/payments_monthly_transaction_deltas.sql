{{ config(store_failures = true) }}

WITH payments_rides AS (

    SELECT *
    FROM {{ ref('payments_rides') }}

),

extract_count_date AS (

    SELECT

        participant_id,
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
    GROUP BY yearmonth, participant_id
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (PARTITION BY participant_id ORDER BY yearmonth)
            ) / LAG(ridership_count, 1) OVER (PARTITION BY participant_id ORDER BY yearmonth)
        ) * 100
        AS relative_difference

    FROM extract_count_date

),

payments_monthly_transaction_deltas AS (

    SELECT

        participant_id,
        yearmonth,
        ridership_count,
        relative_difference

    FROM
        (SELECT
            participant_id,
            yearmonth,
            ridership_count,
            relative_difference,
            RANK() OVER (PARTITION BY participant_id ORDER BY yearmonth DESC) AS rank
            FROM calculate_relative_difference)
    WHERE rank != 1
        AND rank < 5
    ORDER BY yearmonth

)

SELECT * FROM payments_monthly_transaction_deltas
