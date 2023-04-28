{{ config(materialized='table') }}

WITH elavon_billing AS (
    SELECT * FROM  {{ ref('fct_elavon__transactions') }}
    WHERE batch_type = 'B'
),

fct_payments_rides_v2 AS (
    SELECT * FROM  {{ ref('fct_payments_rides_v2') }}
),

payments_tests_daily_date_spine AS (
    SELECT * FROM  {{ ref('payments_tests_daily_date_spine') }}
),

billing_agg AS(

    SELECT

        customer_name,
        payment_date,
        -- this same treatment for the other customers?
        IF(customer_name = 'MST TAP TO RIDE', 'mst', customer_name) as participant_id,
        SUM(amount) AS billing_sum

    FROM elavon_billing
    GROUP BY customer_name, payment_date
),

littlepay_agg AS (
    SELECT
        participant_id,
        transaction_date_pacific,
        SUM(charge_amount) AS littlepay_sums
    FROM fct_payments_rides_v2
    GROUP BY participant_id, transaction_date_pacific
),

daily_history__littlepay_revenue_and_elavon_billing AS (

    SELECT
        t1.participant_id,
        t1.day_history,
        t2.littlepay_sums,
        t3.billing_sum
    FROM payments_tests_daily_date_spine AS t1
    LEFT JOIN littlepay_agg AS t2
        ON (t1.day_history = t2.transaction_date_pacific) AND (t1.participant_id = t2.participant_id)
    LEFT JOIN billing_agg as t3
        ON (t1.day_history = t3.payment_date) AND (t1.participant_id = t3.participant_id)
)

SELECT *  FROM daily_history__littlepay_revenue_and_elavon_billing
