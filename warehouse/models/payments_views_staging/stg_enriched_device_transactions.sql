---
description: "This task makes the assumption that, in the case of duplicated littlepay_transaction_id values, the one with the latest transaction_date_time_utc in the latest export file takes precedence."
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_device_transactions"

external_dependencies:
  - payments_loader: all
---

WITH

enriched AS (
    {{

      sql_enrich_duplicates(
        "payments.device_transactions",
        ["littlepay_transaction_id"],
        ["calitp_file_name desc", "transaction_date_time_utc desc"]
      )

    }}
)

SELECT *,
       DATETIME(TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles") AS transaction_date_time_pacific,
FROM enriched
