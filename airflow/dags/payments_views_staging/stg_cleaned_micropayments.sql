---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_micropayments"

description: >
  A micropayment represents a debit or credit that should be made against the
  customer's funding source for a trip. Multiple micropayments can be aggregated
  and settled together. Credit micropayments can be created if a refund is
  requested for the travel associated with a debit micropayment before the
  aggregation containing the debit micropayment is settled.

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
