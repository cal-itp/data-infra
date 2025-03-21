WITH device_transactions AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_device_transactions') }}
),

pairs AS (
    SELECT *
    FROM {{ ref('int_payments__matched_device_transactions') }}
),

joined_transactions AS (
    SELECT
        pairs.participant_id,
        pairs.micropayment_id,
        pairs.littlepay_transaction_id AS littlepay_transaction_id_1,
        pairs.off_littlepay_transaction_id AS littlepay_transaction_id_2,
        tap_on.customer_id AS customer_id_1,
        tap_off.customer_id AS customer_id_2,
        tap_on.device_id AS device_id_1,
        tap_off.device_id AS device_id_2,
        tap_on.device_id_issuer AS device_id_issuer_1,
        tap_off.device_id_issuer AS device_id_issuer_2,
        tap_on.route_id AS route_id_1,
        tap_off.route_id AS route_id_2,
        tap_on.mode AS mode_1,
        tap_off.mode AS mode_2,
        tap_on.direction AS direction_1,
        tap_off.direction AS direction_2,
        tap_on.vehicle_id AS vehicle_id_1,
        tap_off.vehicle_id AS vehicle_id_2,

        (tap_on.customer_id != tap_off.customer_id AND (tap_on.customer_id IS NOT NULL OR tap_off.customer_id IS NOT NULL)) AS has_mismatched_customer_id,
        (tap_on.device_id != tap_off.device_id AND (tap_on.device_id IS NOT NULL OR tap_off.device_id IS NOT NULL)) AS has_mismatched_device_id,
        (tap_on.device_id_issuer != tap_off.device_id_issuer AND (tap_on.device_id_issuer IS NOT NULL OR tap_off.device_id_issuer IS NOT NULL)) AS has_mismatched_device_id_issuer,
        (tap_on.route_id != tap_off.route_id AND (tap_on.route_id IS NOT NULL OR tap_off.route_id IS NOT NULL)) AS has_mismatched_route_id,
        (tap_on.mode != tap_off.mode AND (tap_on.mode IS NOT NULL OR tap_off.mode IS NOT NULL)) AS has_mismatched_mode,
        (tap_on.direction != tap_off.direction AND (tap_on.direction IS NOT NULL OR tap_off.direction IS NOT NULL)) AS has_mismatched_direction,
        (tap_on.vehicle_id != tap_off.vehicle_id AND (tap_on.vehicle_id IS NOT NULL OR tap_off.vehicle_id IS NOT NULL)) AS has_mismatched_vehicle_id

    FROM pairs
    LEFT JOIN device_transactions AS tap_on
    USING (littlepay_transaction_id)
    INNER JOIN device_transactions AS tap_off
    ON pairs.off_littlepay_transaction_id = tap_off.littlepay_transaction_id
),

int_payments__device_transaction_pairs_common_fields AS (

    SELECT *
    FROM joined_transactions
    WHERE has_mismatched_customer_id
        OR has_mismatched_device_id_issuer
        OR has_mismatched_route_id
        OR has_mismatched_mode
        OR has_mismatched_direction
        OR has_mismatched_vehicle_id
)

SELECT * FROM int_payments__device_transaction_pairs_common_fields
