---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `payments.micropayment_device_transactions` (
  littlepay_transaction_id STRING,
  micropayment_id STRING
)
OPTIONS (
  format = "csv",
  uris = ["gs://littlepay-data-extract-prod/mst/micropayment-device-transactions/*"],
  field_delimiter = "|",
  skip_leading_rows = 1
)
