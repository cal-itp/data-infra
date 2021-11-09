---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_device_transaction_common_fields"

description: >
  Ensure that fields that are expected to be consistent across tap on/off
  transactions are actually consistent. Invalid records are any that differ on
  the device_id, device_id_issuer, route_id, mode, direction, of vehicle_id
  fields.

dependencies:
  - stg_cleaned_device_transactions
  - stg_cleaned_device_transaction_types
  - stg_cleaned_micropayment_device_transactions

tests:
  check_empty:
    - "*"
---

WITH

initial_transactions AS (
    SELECT *
    FROM `payments.stg_cleaned_micropayment_device_transactions`
    JOIN `payments.stg_cleaned_device_transactions` USING (littlepay_transaction_id)
    JOIN `payments.stg_cleaned_device_transaction_types` USING (littlepay_transaction_id)
    WHERE transaction_type = 'on'
),

second_transactions AS (
    SELECT *
    FROM `payments.stg_cleaned_micropayment_device_transactions`
    JOIN `payments.stg_cleaned_device_transactions` USING (littlepay_transaction_id)
    JOIN `payments.stg_cleaned_device_transaction_types` USING (littlepay_transaction_id)
    WHERE transaction_type = 'off'
)

SELECT participant_id,
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
       t2.vehicle_id AS vehicle_id_2
FROM initial_transactions AS t1
JOIN second_transactions AS t2 USING (participant_id, micropayment_id)
WHERE
    -- (t1.customer_id <> t2.customer_id AND (t1.customer_id IS NOT NULL OR t2.customer_id IS NOT NULL))
    -- OR
    (t1.device_id <> t2.device_id AND (t1.device_id IS NOT NULL OR t2.device_id IS NOT NULL))
    OR
    (t1.device_id_issuer <> t2.device_id_issuer AND (t1.device_id_issuer IS NOT NULL OR t2.device_id_issuer IS NOT NULL))
    OR
    (t1.route_id <> t2.route_id AND (t1.route_id IS NOT NULL OR t2.route_id IS NOT NULL))
    OR
    (t1.mode <> t2.mode AND (t1.mode IS NOT NULL OR t2.mode IS NOT NULL))
    OR
    (t1.direction <> t2.direction AND (t1.direction IS NOT NULL OR t2.direction IS NOT NULL))
    OR
    (t1.vehicle_id <> t2.vehicle_id AND (t1.vehicle_id IS NOT NULL OR t2.vehicle_id IS NOT NULL))
