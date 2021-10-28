---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_micropayments"

dependencies:
  - stg_enriched_micropayments

tests:
  check_unique:
    - micropayment_id
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number)
from payments.stg_enriched_micropayments
where calitp_dupe_number = 1
