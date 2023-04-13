WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_v2') }}
),

payments_tests_monthly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_monthly_date_spine') }}
),

extract_count_month AS (
    SELECT

        participant_id,
        month_start,
        COUNT(*) AS ridership_count

    FROM payments_tests_monthly_date_spine
    INNER JOIN payments_rides
        USING (participant_id) WHERE transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

match_date_spine AS (
    SELECT

        participant_id,
        month_start,
        ridership_count

    FROM payments_tests_monthly_date_spine
    LEFT JOIN extract_count_month
        USING (participant_id, month_start)
),

calculate_relative_difference AS (
    SELECT

        *,
        (
            (
                ridership_count - LAG(
                    ridership_count, 1
                ) OVER (PARTITION BY participant_id ORDER BY month_start)
            ) / LAG(ridership_count, 1) OVER (PARTITION BY participant_id ORDER BY month_start)
        ) * 100
        AS relative_difference

    FROM match_date_spine
),

v2_payments_monthly_transaction_deltas AS (
    SELECT

        participant_id,
        month_start,
        COALESCE(ridership_count, 0) AS ridership_count,
        relative_difference,
        recency_rank

    FROM
        (SELECT
            participant_id,
            month_start,
            ridership_count,
            relative_difference,
            RANK() OVER (PARTITION BY participant_id ORDER BY month_start DESC) AS recency_rank
            FROM calculate_relative_difference)
)

SELECT * FROM v2_payments_monthly_transaction_deltas
