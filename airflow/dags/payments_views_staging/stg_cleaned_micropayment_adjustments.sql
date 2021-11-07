---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_micropayment_adjustments"

dependencies:
  - stg_enriched_micropayment_adjustments

tests:
  check_unique_together:
    - micropayment_id
    - adjustment_id
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number)
from payments.stg_enriched_micropayment_adjustments
where calitp_dupe_number = 1
