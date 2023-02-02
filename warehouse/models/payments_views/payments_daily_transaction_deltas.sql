WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

payments_tests_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_date_spine') }}
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

add_date_spine AS (
    SELECT

        t1.participant_id,
        t1.day_history AS transaction_date,

        t2.ridership_count

    FROM payments_tests_date_spine AS t1
    LEFT JOIN extract_count_date AS t2
        ON (t1.day_history = t2.transaction_date)
            AND (t1.participant_id = t2.participant_id)
),

payments_daily_transaction_deltas AS (
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

    FROM add_date_spine
)

SELECT * FROM payments_daily_transaction_deltas
