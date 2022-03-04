---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_authorisations"

description: >
  Authorisations are sent to the acquiring bank to get approval to charge a card
  or to verify that a card is valid. Authorisations are performed against
  aggregations containing micropayments. Authorisations that are declined may be
  reattempted later as part of a debt recovery process.

dependencies:
  - stg_enriched_authorisations
---

select distinct * except (
    calitp_file_name,
    calitp_n_dupes,
    calitp_n_dupe_ids,
    calitp_dupe_number)
from payments.stg_enriched_authorisations
where calitp_dupe_number = 1
