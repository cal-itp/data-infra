WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

payments_tests_weekly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_weekly_date_spine') }}
),

extract_count_week AS (
    SELECT

        participant_id,
        week_start,
        COUNT(*) AS ridership_count

    FROM payments_rides
    LEFT JOIN payments_tests_weekly_date_spine
        USING (participant_id) WHERE transaction_date_pacific >= week_start AND transaction_date_pacific <= week_end
    GROUP BY week_start, participant_id
),


calculate_relative_difference AS (
    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (PARTITION BY participant_id ORDER BY week_start)
            ) / LAG(ridership_count, 1) OVER (PARTITION BY participant_id ORDER BY week_start)
        ) * 100
        AS relative_difference

    FROM extract_count_week
),

payments_weekly_transaction_deltas AS (
    SELECT

        participant_id,
        week_start,
        COALESCE(ridership_count, 0) AS ridership_count,
        relative_difference,
        recency_rank

    FROM
        (SELECT
            participant_id,
            week_start,
            ridership_count,
            relative_difference,
            RANK() OVER (PARTITION BY participant_id ORDER BY week_start DESC) AS recency_rank
            FROM calculate_relative_difference)
    WHERE recency_rank != 1
)

SELECT * FROM payments_weekly_transaction_deltas
