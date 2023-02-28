WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

route_z_rides AS (
    SELECT * FROM payments_rides
    WHERE route_id = 'Route Z'
),

null_rides AS (
    SELECT * FROM payments_rides
    WHERE route_id IS NULL
),

payments_tests_monthly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_monthly_date_spine') }}
),

count_route_z_rides AS (
    SELECT

        spine.participant_id,
        spine.month_start,
        COUNT(*) AS n_route_z_rides

    FROM payments_tests_monthly_date_spine AS spine
    INNER JOIN route_z_rides
        ON (spine.participant_id = route_z_rides.participant_id) AND transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

count_null_rides AS (
    SELECT

        spine.participant_id,
        spine.month_start,
        COUNT(*) AS n_null_rides

    FROM payments_tests_monthly_date_spine AS spine
    INNER JOIN null_rides
        ON (spine.participant_id = null_rides.participant_id) AND transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

count_all_rides AS (
    SELECT

        spine.participant_id,
        spine.month_start,
        COUNT(*) AS n_all_rides

    FROM payments_tests_monthly_date_spine AS spine
    INNER JOIN payments_rides
        ON (spine.participant_id = payments_rides.participant_id) AND transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

match_date_spine AS (
    SELECT

        date_spine.participant_id,
        date_spine.month_start,
        COALESCE(z_rides.n_route_z_rides, 0) AS n_route_z_rides,
        COALESCE(null_rides.n_null_rides, 0) AS n_null_rides,
        (COALESCE(z_rides.n_route_z_rides, 0) + COALESCE(null_rides.n_null_rides, 0)) AS total_unlabeled_rides,
        COALESCE(all_rides.n_all_rides, 0) AS n_all_rides

    FROM payments_tests_monthly_date_spine AS date_spine
    LEFT JOIN count_all_rides AS all_rides
        USING (participant_id, month_start)
    LEFT JOIN count_route_z_rides AS z_rides
        USING (participant_id, month_start)
    LEFT JOIN count_null_rides AS null_rides
        USING (participant_id, month_start)
),

calculate_relative_count AS (
    SELECT

        *,

        SAFE_DIVIDE(total_unlabeled_rides, n_all_rides) * 100 AS percentage_unlabeled_rides_to_total_rides,

    FROM match_date_spine
),

payments_reliability_unlabeled_routes AS (
    SELECT

        participant_id,
        month_start,
        n_route_z_rides,
        n_null_rides,
        total_unlabeled_rides,
        n_all_rides,
        percentage_unlabeled_rides_to_total_rides,
        recency_rank

    FROM
        (SELECT
            participant_id,
            month_start,
            n_route_z_rides,
            n_null_rides,
            total_unlabeled_rides,
            n_all_rides,
            percentage_unlabeled_rides_to_total_rides,

            RANK() OVER (PARTITION BY participant_id ORDER BY month_start DESC) AS recency_rank

        FROM calculate_relative_count)
)

SELECT * FROM payments_reliability_unlabeled_routes
