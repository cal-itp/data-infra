---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_product_data"

dependencies:
  - stg_enriched_product_data

tests:
  check_unique:
    - product_id
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number)
from payments.stg_enriched_product_data
where calitp_dupe_number = 1
