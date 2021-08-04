---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE EXTERNAL TABLE `payments.customer_funding_source` OPTIONS (
   format = "csv",
   uris = ["gs://littlepay-data-extract-prod/mst/customer-funding-source/*.psv"],
   field_delimiter = "|",
   skip_leading_rows = 1
)
