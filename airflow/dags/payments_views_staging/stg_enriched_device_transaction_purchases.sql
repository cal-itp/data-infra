---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_device_transaction_purchases"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.device_transaction_purchases",
    ["purchase_id"],
    ["calitp_file_name desc"]
  )

}}
