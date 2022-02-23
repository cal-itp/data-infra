---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_micropayment_device_transactions"

description: >
  A device transaction should only ever be associated with a single debit
  micropayment. This table contains micropayment information where that
  invariant does not hold true.

dependencies:
  - stg_cleaned_micropayment_device_transactions

tests:
  check_empty:
    - "*"
---

with

multiple_debit_transaction_ids as (
    select littlepay_transaction_id
    from `payments.stg_cleaned_micropayment_device_transactions`
    join `payments.stg_cleaned_micropayments` m using (micropayment_id)
    where m.type = 'DEBIT'
    group by 1
    having count(*) > 1
)

select littlepay_transaction_id, m.*
from `payments.stg_cleaned_micropayment_device_transactions`
join `payments.stg_cleaned_micropayments` m using (micropayment_id)
join multiple_debit_transaction_ids using (littlepay_transaction_id)
order by transaction_time desc, littlepay_transaction_id, charge_type desc
