---
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
