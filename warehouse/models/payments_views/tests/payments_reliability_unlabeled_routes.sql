WITH payments_rides AS (
    SELECT * FROM {{ ref('payments_rides') }}
),

payments_tests_monthly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_monthly_date_spine') }}
),

count_rides AS (
    SELECT

        spine.participant_id,
        spine.month_start,
        COUNTIF(route_id = 'Route Z') AS n_route_z_rides,
        COUNTIF(route_id IS NULL) AS n_null_rides,
        COUNT(*) AS n_all_rides

    FROM payments_tests_monthly_date_spine AS spine
    INNER JOIN payments_rides
        ON (spine.participant_id = payments_rides.participant_id) AND transaction_date_pacific >= month_start AND transaction_date_pacific <= month_end
    GROUP BY month_start, participant_id
),

aggregations_and_date_spine AS (
    SELECT

        date_spine.participant_id,
        date_spine.month_start,
        count_rides.n_route_z_rides,
        count_rides.n_null_rides,
        count_rides.n_all_rides,

        (count_rides.n_route_z_rides + count_rides.n_null_rides) AS total_unlabeled_rides,

        SAFE_DIVIDE((count_rides.n_route_z_rides + count_rides.n_null_rides), count_rides.n_all_rides) * 100 AS percentage_unlabeled_rides_to_total_rides

    FROM payments_tests_monthly_date_spine AS date_spine
    LEFT JOIN count_rides
        USING (participant_id, month_start)
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

        FROM aggregations_and_date_spine)
)

SELECT * FROM payments_reliability_unlabeled_routes
