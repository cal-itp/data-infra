WITH payments_rides AS (

    SELECT *
    FROM {{ ref('payments_rides') }}

),

extract_count_date AS (

    SELECT

        participant_id,
        COUNT(*) AS ridership_count,
        DATE(
            EXTRACT(DATE FROM transaction_date_time_pacific)
        ) AS transaction_date

    FROM payments_rides
    GROUP BY transaction_date, participant_id
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (PARTITION BY participant_id ORDER BY transaction_date)
            ) / LAG(ridership_count, 1)
            OVER (PARTITION BY participant_id ORDER BY transaction_date)) * 100
        AS relative_difference

    FROM extract_count_date

),

payments_daily_transaction_deltas AS (

    SELECT

        participant_id,
        transaction_date,
        ridership_count,
        relative_difference

    FROM calculate_relative_difference

)

SELECT * FROM payments_daily_transaction_deltas
