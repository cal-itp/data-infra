{{ config(materialized='table') }}

WITH stg_elavon__billing AS (
    SELECT * FROM  {{ ref('stg_elavon__billing') }}
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
        IF(customer_name = 'MST TAP TO RIDE', 'mst', customer_name) as participant_id,
        SUM(amount) AS billing_sum

    FROM stg_elavon__billing
    -- this is a quick and dirty dedupe and needs to be replaced
    WHERE dt = '2023-04-10'
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

stg_fee_comparison AS (

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

SELECT *  FROM stg_fee_comparison
