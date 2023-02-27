WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

route_z_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
    WHERE route_id = 'Route Z'
),

payments_tests_monthly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_monthly_date_spine') }}
),

count_all_route_z_rides AS (
    SELECT

        participant_id,
        month_start,
        COUNT(*) AS n_route_z_rides

    FROM payments_tests_monthly_date_spine
    INNER JOIN route_z_rides
        USING (participant_id) WHERE transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

count_all_rides AS (
    SELECT

        participant_id,
        month_start,
        COUNT(*) AS n_all_rides

    FROM payments_tests_monthly_date_spine
    INNER JOIN payments_rides
        USING (participant_id) WHERE transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

join_counts AS (
    SELECT

        z_rides.participant_id,
        z_rides.month_start,
        z_rides.n_route_z_rides,
        all_rides.n_all_rides

    FROM count_all_route_z_rides AS z_rides
    INNER JOIN count_all_rides AS all_rides
        USING (participant_id, month_start)

),

match_date_spine AS (
    SELECT

        participant_id,
        month_start,
        COALESCE(n_route_z_rides, 0) AS n_route_z_rides,
        COALESCE(n_all_rides, 0) AS n_all_rides

    FROM payments_tests_monthly_date_spine
    LEFT JOIN join_counts
        USING (participant_id, month_start)
),

calculate_relative_count AS (
    SELECT

        *,

        SAFE_DIVIDE(n_route_z_rides, n_all_rides) * 100 AS relative_count_route_z

    FROM match_date_spine
),

payments_monthly_route_z_relative_to_total AS (
    SELECT

        participant_id,
        month_start,
        n_route_z_rides,
        n_all_rides,
        relative_count_route_z,
        recency_rank

    FROM
        (SELECT
            participant_id,
            month_start,
            n_route_z_rides,
            n_all_rides,
            relative_count_route_z,

            RANK() OVER (PARTITION BY participant_id ORDER BY month_start DESC) AS recency_rank

        FROM calculate_relative_count)
)

SELECT * FROM payments_monthly_route_z_relative_to_total
