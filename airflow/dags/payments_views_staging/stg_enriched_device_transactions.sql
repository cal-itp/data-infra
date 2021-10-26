---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_device_transactions"

external_dependencies:
  - payments_loader: all
---

{{

  sql_enrich_duplicates(
    "payments.device_transactions",
    ["littlepay_transaction_id"],
    ["calitp_file_name desc", "transaction_date_time_utc desc"]
  )

}}
