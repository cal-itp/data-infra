---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_device_transactions"

dependencies:
  - stg_enriched_device_transactions

tests:
  check_unique:
    - littlepay_transaction_id
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number,
    route_id,
    location_id),
    trim(route_id) as route_id,
    trim(location_id) as location_id
from payments.stg_enriched_device_transactions
where calitp_dupe_number = 1
