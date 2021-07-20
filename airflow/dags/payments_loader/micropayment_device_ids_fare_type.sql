---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.micropayment_device_ids_fare_type"
dependencies:
  - micropayments
  - micropayment_device_transactions
---

SELECT t1.charge_type,
       t1.micropayment_id,
       t1.charge_amount,
       t2.littlepay_transaction_id
FROM `payments.micropayments` as t1
LEFT JOIN `payments.micropayment_device_transactions` as t2
ON
t1.micropayment_id = t2.micropayment_id
