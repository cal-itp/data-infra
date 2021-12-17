---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_micropayment_transaction_time_order"

description: >
  The timestamp on micropayment records should be at least as late as its
  associated transactions timestamps.

dependencies:
  - stg_cleaned_micropayments
  - stg_cleaned_micropayment_device_transactions
  - stg_cleaned_device_transactions
---

SELECT
    micropayment_id,
    cast(transaction_time AS TIMESTAMP) AS transaction_time,
    littlepay_transaction_id,
    cast(transaction_date_time_utc AS TIMESTAMP) AS transaction_date_time_utc
FROM payments.stg_cleaned_micropayments
JOIN payments.stg_cleaned_micropayment_device_transactions USING (micropayment_id)
JOIN payments.stg_cleaned_device_transactions USING (littlepay_transaction_id)
WHERE cast(transaction_time AS TIMESTAMP) < cast(transaction_date_time_utc AS TIMESTAMP)
