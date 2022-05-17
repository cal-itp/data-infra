---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_refunds"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.refunds",
    ["refund_id"],
    ["calitp_file_name desc"]
  )

}}
