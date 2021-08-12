---
operator: operators.SqlQueryOperator
---


CREATE OR REPLACE EXTERNAL TABLE `payments.device_transactions` (
   participant_id STRING,
   customer_id STRING,
   device_transaction_id STRING,
   littlepay_transaction_id STRING,
   device_id STRING,
   device_id_issuer STRING,
   type STRING,
   transaction_outcome STRING,
   transction_deny_reason STRING,
   transaction_date_time_utc STRING,
   location_id STRING,
   location_scheme STRING,
   location_name STRING,
   zone_id STRING,
   route_id STRING,
   mode STRING,
   direction STRING,
   latitude STRING,
   longitude STRING,
   vehicle_id STRING,
   granted_zone_ids STRING,
   onward_zone_ids STRING
)
OPTIONS (
  format = "csv",
  uris = ["gs://littlepay-data-extract-prod/mst/device-transactions/*.psv"],
  field_delimiter = "|",
  skip_leading_rows = 1
)
