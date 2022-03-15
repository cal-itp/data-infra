---
operator: operators.SqlQueryOperator

dependencies:
  - benefits_events
---

 CREATE OR REPLACE EXTERNAL TABLE `amplitude.benefits_events` (
  app INT64,
  device_id STRING,
  user_id STRING,
  client_event_time TIMESTAMP,
  event_id INT64,
  session_id INT64,
  event_type STRING,
  amplitude_event_type STRING,
  version_name STRING,
  platform STRING,
  os_name STRING,
  os_version STRING,
  device_brand STRING,
  device_manufacturer STRING,
  device_model STRING,
  device_family STRING,
  device_type STRING,
  device_carrier STRING,
  location_lat STRING,
  location_lng STRING,
  ip_address STRING,
  country STRING,
  language STRING,
  library STRING,
  city STRING,
  region STRING,
  dma STRING,
  event_properties STRUCT<
      provider_name STRING,
      path STRING
      >,
  user_properties STRUCT<
    referring_domain STRING,
    user_agent STRING,
    referrer STRING
    >,
  event_time STRING,
  client_upload_time TIMESTAMP,
  server_upload_time TIMESTAMP,
  server_received_time TIMESTAMP,
  amplitude_id INT64,
  idfa STRING,
  adid STRING,
  paying STRING,
  start_version STRING,
  user_creation_time STRING,
  uuid STRING,
  sample_rate STRING,
  insert_id STRING,
  insert_key STRING,
  is_attribution_event BOOL,
  amplitude_attribution_ids STRING,
  partner_id STRING,
  schema INT64,
  processed_time TIMESTAMP
)
OPTIONS (
    format = "JSON",
    uris = ["{{get_bucket()}}/amplitude/benefits/*.jsonl"],
    ignore_unknown_values = True
)
