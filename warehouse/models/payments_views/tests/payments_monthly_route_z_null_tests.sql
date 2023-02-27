WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
    WHERE route_id = 'Route Z'
        OR route_id IS NULL
),

payments_tests_monthly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_monthly_date_spine') }}
),

extract_count_month AS (
    SELECT

        participant_id,
        month_start,
        COUNT(*) AS count_route_z_null

    FROM payments_tests_monthly_date_spine
    INNER JOIN payments_rides
        USING (participant_id) WHERE transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

match_date_spine AS (
    SELECT

        participant_id,
        month_start,
        count_route_z_null

    FROM payments_tests_monthly_date_spine
    LEFT JOIN extract_count_month
        USING (participant_id, month_start)
),

calculate_relative_difference AS (
    SELECT

        *,
        (
            (
                count_route_z_null - LAG(
                    count_route_z_null, 1
                ) OVER (PARTITION BY participant_id ORDER BY month_start)
            ) / LAG(count_route_z_null, 1) OVER (PARTITION BY participant_id ORDER BY month_start)
        ) * 100
        AS relative_difference

    FROM match_date_spine
),

payments_monthly_route_z_null_tests AS (
    SELECT

        participant_id,
        month_start,
        COALESCE(count_route_z_null, 0) AS route_z_null_count,
        relative_difference,
        recency_rank

    FROM
        (SELECT
            participant_id,
            month_start,
            count_route_z_null,
            relative_difference,
            RANK() OVER (PARTITION BY participant_id ORDER BY month_start DESC) AS recency_rank
            FROM calculate_relative_difference)
)

SELECT * FROM payments_monthly_route_z_null_tests
