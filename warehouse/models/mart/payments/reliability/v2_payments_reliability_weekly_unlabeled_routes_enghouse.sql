{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH payments_rides AS (
    SELECT * FROM {{ ref('fct_payments_rides_enghouse') }}
),

payments_tests_weekly_date_spine AS (
    SELECT * FROM {{ ref('payments_tests_weekly_date_spine_enghouse') }}
),

count_rides AS (
    SELECT

        spine.operator_id,
        spine.week_start,
        COUNTIF(line_public_number IS NULL) AS n_null_rides,
        COUNTIF(line_public_number = '') AS n_empty_string_rides,
        COUNT(*) AS n_all_rides

    FROM payments_tests_weekly_date_spine AS spine
    INNER JOIN payments_rides
        ON (spine.operator_id = payments_rides.operator_id) AND DATE(start_dttm) >= week_start AND DATE(start_dttm) <= week_end
    GROUP BY week_start, operator_id
),

aggregations_and_date_spine AS (
    SELECT

        date_spine.operator_id,
        date_spine.week_start,
        count_rides.n_null_rides,
        count_rides.n_empty_string_rides,
        count_rides.n_all_rides,

        (count_rides.n_null_rides + count_rides.n_empty_string_rides) AS total_unlabeled_rides,

        SAFE_DIVIDE((count_rides.n_null_rides + count_rides.n_empty_string_rides), count_rides.n_all_rides) * 100 AS pct_unlabeled_rides_to_total_rides

    FROM payments_tests_weekly_date_spine AS date_spine
    LEFT JOIN count_rides
        USING (operator_id, week_start)
),

v2_payments_reliability_weekly_unlabeled_routes_enghouse AS (
    SELECT

        operator_id,
        week_start,
        n_null_rides,
        total_unlabeled_rides,
        n_empty_string_rides,
        n_all_rides,
        pct_unlabeled_rides_to_total_rides,
        RANK() OVER (PARTITION BY operator_id ORDER BY week_start DESC) AS recency_rank

    FROM aggregations_and_date_spine
)

SELECT * FROM v2_payments_reliability_weekly_unlabeled_routes_enghouse
