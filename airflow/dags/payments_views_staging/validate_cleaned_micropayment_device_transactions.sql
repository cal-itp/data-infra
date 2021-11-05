---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_micropayment_device_transactions"

dependencies:
  - stg_cleaned_micropayment_device_transactions

tests:
  check_empty:
    - "*"
---

with

multplied_transaction_ids as (
    select littlepay_transaction_id
    from `payments.stg_cleaned_micropayment_device_transactions`
    group by 1
    having count(*) > 1
)

select littlepay_transaction_id, m.*
from `payments.stg_cleaned_micropayment_device_transactions`
join `payments.stg_cleaned_micropayments` m using (micropayment_id)
join multplied_transaction_ids using (littlepay_transaction_id)
order by transaction_time desc, littlepay_transaction_id, charge_type desc
