WITH device_transactions AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transactions') }}
),

pairs AS (
    SELECT *
    FROM {{ ref('int_payments__matched_device_transactions') }}
)

joined_transactions AS (
    SELECT
        participant_id,
        micropayment_id,
        t1.littlepay_transaction_id AS littlepay_transaction_id_1,
        t2.littlepay_transaction_id AS littlepay_transaction_id_2,
        t1.customer_id AS customer_id_1,
        t2.customer_id AS customer_id_2,
        t1.device_id AS device_id_1,
        t2.device_id AS device_id_2,
        t1.device_id_issuer AS device_id_issuer_1,
        t2.device_id_issuer AS device_id_issuer_2,
        t1.route_id AS route_id_1,
        t2.route_id AS route_id_2,
        t1.mode AS mode_1,
        t2.mode AS mode_2,
        t1.direction AS direction_1,
        t2.direction AS direction_2,
        t1.vehicle_id AS vehicle_id_1,
        t2.vehicle_id AS vehicle_id_2,

        (t1.customer_id != t2.customer_id AND (t1.customer_id IS NOT NULL OR t2.customer_id IS NOT NULL)) AS has_mismatched_customer_id,
        (t1.device_id != t2.device_id AND (t1.device_id IS NOT NULL OR t2.device_id IS NOT NULL)) AS has_mismatched_device_id,
        (t1.device_id_issuer != t2.device_id_issuer AND (t1.device_id_issuer IS NOT NULL OR t2.device_id_issuer IS NOT NULL)) AS has_mismatched_device_id_issuer,
        (t1.route_id != t2.route_id AND (t1.route_id IS NOT NULL OR t2.route_id IS NOT NULL)) AS has_mismatched_route_id,
        (t1.mode != t2.mode AND (t1.mode IS NOT NULL OR t2.mode IS NOT NULL)) AS has_mismatched_mode,
        (t1.direction != t2.direction AND (t1.direction IS NOT NULL OR t2.direction IS NOT NULL)) AS has_mismatched_direction,
        (t1.vehicle_id != t2.vehicle_id AND (t1.vehicle_id IS NOT NULL OR t2.vehicle_id IS NOT NULL)) AS has_mismatched_vehicle_id

    FROM pairs
    LEFT JOIN device_transactions AS t1
    INNER JOIN device_transactions AS t2 USING (participant_id, micropayment_id)
),

int_device_transaction_pairs_common_fields AS (

    SELECT *
    FROM joined_transactions
    WHERE has_mismatched_customer_id
        OR has_mismatched_device_id
        OR has_mismatched_device_id_issuer
        OR has_mismatched_route_id
        OR has_mismatched_mode
        OR has_mismatched_direction
        OR has_mismatched_vehicle_id
)

SELECT * FROM int_device_transaction_pairs_common_fields
