---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_product_data"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.product_data",
    ["calitp_hash"],
    ["calitp_file_name desc"]
  )

}}
