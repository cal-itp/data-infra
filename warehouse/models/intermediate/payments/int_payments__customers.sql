WITH stg_littlepay__customer_funding_source AS (
    SELECT *
    FROM {{ ref('stg_littlepay__customer_funding_source') }}
),

-- We want the last occurrence by funding_source_id and customer_id
select_first_rank AS (
    SELECT DISTINCT
        participant_id,
        customer_id,
        principal_customer_id
    FROM stg_littlepay__customer_funding_source
    WHERE calitp_customer_id_rank = 1
        AND calitp_funding_source_id_rank = 1
),

find_earliest_tap AS (
    SELECT
        participant_id,
        customer_id,
        MIN(transaction_date_time_pacific) AS earliest_tap
    FROM {{ ref('stg_littlepay__device_transactions') }}
    GROUP BY participant_id, customer_id

),

int_payments__customers AS (
    SELECT
        t1.participant_id,
        t1.customer_id,
        t1.principal_customer_id,
        t2.earliest_tap
    FROM select_first_rank AS t1
    LEFT JOIN find_earliest_tap AS t2 USING (customer_id, participant_id)
)

SELECT * FROM int_payments__customers
