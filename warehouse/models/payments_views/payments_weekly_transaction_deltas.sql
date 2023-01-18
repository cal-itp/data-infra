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
                    EXTRACT(WEEK FROM transaction_date_time_pacific) AS string
                ),
                2,
                '0'
            )
        ) AS yearweek

    FROM payments_rides
    GROUP BY yearweek, participant_id
),


calculate_relative_difference AS (

    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (PARTITION BY participant_id ORDER BY yearweek)
            ) / LAG(ridership_count, 1) OVER (PARTITION BY participant_id ORDER BY yearweek)
        ) * 100
        AS relative_difference

    FROM extract_count_date
    WHERE yearweek NOT LIKE '%-00'

),

payments_weekly_transaction_deltas AS (

    SELECT

        participant_id,
        yearweek,
        ridership_count,
        relative_difference,
        recency_rank

    FROM
        (SELECT
            participant_id,
            yearweek,
            ridership_count,
            relative_difference,
            RANK() OVER (PARTITION BY participant_id ORDER BY yearweek DESC) AS recency_rank
            FROM calculate_relative_difference)

)

SELECT * FROM payments_weekly_transaction_deltas
