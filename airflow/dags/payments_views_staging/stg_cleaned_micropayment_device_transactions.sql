---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_micropayment_device_transactions"

dependencies:
  - stg_enriched_micropayment_device_transactions

tests:
  check_composite_unique:
    - micropayment_id
    - littlepay_transaction_id
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number)
from payments.stg_enriched_micropayment_device_transactions
where calitp_dupe_number = 1
