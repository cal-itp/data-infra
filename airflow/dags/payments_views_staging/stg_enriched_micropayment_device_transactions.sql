---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_micropayment_device_transactions"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.micropayment_device_transactions",
    ["calitp_hash"],
    ["calitp_file_name desc"]
  )

}}
