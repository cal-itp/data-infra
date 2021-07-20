---
operator: operators.SqlQueryOperator
---


CREATE OR REPLACE EXTERNAL TABLE `payments.device_transactions` OPTIONS (
  format = "csv",
  uris = ["gs://littlepay-data-extract-prod/mst/device-transactions/*.psv"],
  field_delimiter = "|"
)
