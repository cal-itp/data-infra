---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_authorisations"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.authorisations",
    ["calitp_hash"],
    ["calitp_file_name desc"]
  )

}}
