{{ config(materialized='table') }}

WITH

fct_elavon__transactions AS (
    SELECT

        *,
        -- this same treatment for the other customers in the future when we expand dashboard for other customers?
        CASE
          WHEN customer_name = 'MST TAP TO RIDE' THEN 'mst'
          WHEN customer_name = 'CAPITOL CORRIDOR TAP2RIDE' THEN 'ccjpa'
        ELSE customer_name
        END AS participant_id

    FROM  {{ ref('fct_elavon__transactions') }}
),

fct_payments_rides_v2 AS (
    SELECT * FROM  {{ ref('fct_payments_rides_v2') }}
),

payments_tests_daily_date_spine AS (
    SELECT * FROM  {{ ref('payments_tests_daily_date_spine') }}
),

elavon_agg AS(

    SELECT

        payment_date,
        participant_id,
        CASE WHEN batch_type = 'B' THEN SUM(amount) END AS elavon_billing_sum,
        CASE WHEN batch_type = 'D' THEN SUM(amount) END AS elavon_deposits_sum

    FROM fct_elavon__transactions
    GROUP BY payment_date, participant_id, batch_type
),

littlepay_deposits_agg AS (
    SELECT

        participant_id,
        transaction_date_pacific,
        SUM(charge_amount) AS littlepay_transactions_sum

    FROM fct_payments_rides_v2
    GROUP BY transaction_date_pacific, participant_id
),

elavon_littlepay__daily_history_transactions_deposits_billing AS (

    SELECT

        t1.participant_id,
        t1.day_history,
        t2.littlepay_transactions_sum,
        t3.elavon_billing_sum,
        t3.elavon_deposits_sum

    FROM payments_tests_daily_date_spine AS t1
    LEFT JOIN littlepay_deposits_agg AS t2
        ON (t1.day_history = t2.transaction_date_pacific) AND (t1.participant_id = t2.participant_id)
    LEFT JOIN elavon_agg as t3
        ON (t1.day_history = t3.payment_date) AND (t1.participant_id = t3.participant_id)
)

SELECT *  FROM elavon_littlepay__daily_history_transactions_deposits_billing
