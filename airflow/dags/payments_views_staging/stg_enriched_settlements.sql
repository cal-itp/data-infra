---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_settlements"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.settlements",
    ["settlement_id"],
    ["calitp_file_name desc"]
  )

}}
