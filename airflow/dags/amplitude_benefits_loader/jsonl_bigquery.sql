---
operator: operators.SqlQueryOperator

dependencies:
  - benefits_events
---

CREATE OR REPLACE EXTERNAL TABLE `amplitude.benefits_events` (
  app INT64,
  device_id STRING,
  user_id STRING,
  client_event_time DATETIME,
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
  global_user_properties {},
  group_properties {},
  event_time STRING,
  client_upload_time DATETIME,
  server_upload_time DATETIME,
  server_received_time DATETIME,
  amplitude_id INT64,
  idfa STRING,
  adid STRING,
  data {},
  paying STRING,
  start_version STRING,
  user_creation_time STRING,
  uuid STRING,
  groups {},
  sample_rate STRING,
  $insert_id STRING,
  $insert_key STRING,
  is_attribution_event BOOL,
  amplitude_attribution_ids STRING,
  plan {},
  partner_id STRING,
  schema INT64,
  processed_time DATETIME
)
OPTIONS (
    format = "JSON"
    uris = ["{{bucket-name()}}/amplitude/{project}/*.jsonl"],
    ignore_unknown_values = True
)
