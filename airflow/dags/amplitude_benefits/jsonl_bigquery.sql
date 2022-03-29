---
operator: operators.SqlQueryOperator

dependencies:
  - api_to_jsonl
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
    status STRING,
    provider_name STRING,
    path STRING,
    language STRING
    >,
  user_properties STRUCT<
    provider_name STRING,
    referring_domain STRING,
    referrer STRING,
    user_agent STRING
    >,
  event_time TIMESTAMP,
  client_upload_time TIMESTAMP,
  server_upload_time TIMESTAMP,
  server_received_time TIMESTAMP,
  amplitude_id INT64,
  idfa STRING,
  adid STRING,
  paying STRING,
  start_version STRING,
  user_creation_time TIMESTAMP,
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
    uris = ["gs://ingest_amplitude_raw_dev/amplitude/benefits/*.jsonl"],
    ignore_unknown_values = True
)
