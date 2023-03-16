WITH select_first_rank AS (
    SELECT DISTINCT
        customer_id,
        principal_customer_id
    FROM {{ ref('stg_littlepay__customer_funding_source') }}
--     WHERE calitp_dupe_number = 1
--         AND calitp_customer_id_rank = 1
),

find_earliest_tap AS (
    SELECT
        customer_id,
        MIN(transaction_date_time_pacific) AS earliest_tap
    FROM {{ ref('stg_littlepay__device_transactions') }}
    GROUP BY customer_id

),

int_littlepay__customers AS (
    SELECT
        t1.customer_id,
        t1.principal_customer_id,
        t2.earliest_tap
    FROM select_first_rank AS t1
    LEFT JOIN find_earliest_tap AS t2 ON t1.customer_id = t2.customer_id
)

SELECT * FROM int_littlepay__customers
