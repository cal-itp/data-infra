---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `payments.micropayments` OPTIONS (
  format = "csv",
  uris = ["gs://littlepay-data-extract-prod/mst/micropayments/*.psv"],
  field_delimiter = "|"
) 
