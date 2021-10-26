---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_micropayment_adjustments"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.micropayment_adjustments",
    ["adjustment_id"],
    ["calitp_file_name desc"]
  )

}}
