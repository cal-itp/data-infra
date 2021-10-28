---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_customer_funding_sources"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.customer_funding_sources",
    ["funding_source_id"],
    ["calitp_file_name desc"]
  )

}}
