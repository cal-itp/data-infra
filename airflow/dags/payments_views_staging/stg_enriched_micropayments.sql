---
description: "This task makes the assumption that, in the case of duplicated micropayment_id values, the one with the latest transaction_time in the latest export file takes precedence."
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_micropayments"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.micropayments",
    ["micropayment_id"],
    ["calitp_file_name desc", "transaction_time desc"]
  )

}}
