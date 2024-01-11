{{ config(materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}") }}

WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_v2') }}
),

payments_tests_weekly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_weekly_date_spine') }}
),

count_rides AS (
    SELECT

        spine.participant_id,
        spine.week_start,
        COUNTIF(route_id = 'Route Z') AS n_route_z_rides,
        COUNTIF(route_id IS NULL) AS n_null_rides,
        COUNTIF(route_id = '') AS n_empty_string_rides,
        COUNT(*) AS n_all_rides

    FROM payments_tests_weekly_date_spine AS spine
    INNER JOIN payments_rides
        ON (spine.participant_id = payments_rides.participant_id) AND transaction_date_pacific >= week_start AND transaction_date_pacific <= week_end
    GROUP BY week_start, participant_id
),

aggregations_and_date_spine AS (
    SELECT

        date_spine.participant_id,
        date_spine.week_start,
        count_rides.n_route_z_rides,
        count_rides.n_null_rides,
        count_rides.n_empty_string_rides,
        count_rides.n_all_rides,

        (count_rides.n_route_z_rides + count_rides.n_null_rides + count_rides.n_empty_string_rides) AS total_unlabeled_rides,

        SAFE_DIVIDE((count_rides.n_route_z_rides + count_rides.n_null_rides + count_rides.n_empty_string_rides), count_rides.n_all_rides) * 100 AS pct_unlabeled_rides_to_total_rides

    FROM payments_tests_weekly_date_spine AS date_spine
    LEFT JOIN count_rides
        USING (participant_id, week_start)
),

v2_payments_reliability_weekly_unlabeled_routes AS (
    SELECT

        participant_id,
        week_start,
        n_route_z_rides,
        n_null_rides,
        total_unlabeled_rides,
        n_empty_string_rides,
        n_all_rides,
        pct_unlabeled_rides_to_total_rides,
        RANK() OVER (PARTITION BY participant_id ORDER BY week_start DESC) AS recency_rank

    FROM aggregations_and_date_spine
)

SELECT * FROM v2_payments_reliability_weekly_unlabeled_routes
