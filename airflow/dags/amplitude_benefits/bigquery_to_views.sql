---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.amplitude_benefits_events"

dependencies:
  - jsonl_bigquery

description: |
  Benefits application event data from Amplitude, via Google Cloud Services and BigQuery. See more details of data schema here https://developers.amplitude.com/docs/http-api-v2#properties-1

fields:
  amplitude_id: INT64
  app: App name
  city: The current city of the user
  client_event_time: Client event timestamp
  client_upload_time: Client upload time
  country: The current country of the user
  device_family: The device family that the user is using
  device_id: A device-specific identifier such as the Identifier for Vendor on iOS
  device_type: The device type that the user is using
  event_id: An incrementing counter to distinguish events with the same user_id and timestamp from each other
  event_properties_language: Event property language - Application language
  event_properties_path: Event property path - Application path
  event_properties_provider_name: Event property provider name - Transit provider name
  event_properties_status: Eligibility check event property status - cancel, fail or success
  event_time: Event time (e.g. "2021-12-09 00:45:29.430000")
  event_type: The unique identifier for your event
  language: The language set by the user
  processed_time: Processed time
  schema: Schema
  server_received_time: Server received time
  server_upload_time: Server upload time
  session_id: The start time of the session in milliseconds since epoch
  user_creation_time: User creation time
  user_id: A readable ID specified by you
  user_properties_provider_name: User property provider name
  user_properties_referrer: User property preferrer
  user_properties_referring_domain: User property referring domain
  user_properties_user_agent: User property user agent
  uuid: UUID
  version_name: Version name
---

SELECT
  amplitude_id,
  app,
  city,
  client_event_time,
  client_upload_time,
  country,
  device_family,
  device_id,
  device_type,
  event_id,
  event_properties.language AS event_properties_language,
  event_properties.path AS event_properties_path,
  event_properties.provider_name AS event_properties_provider_name,
  event_properties.status AS event_properties_status,
  event_time,
  event_type,
  language,
  processed_time
  schema,
  server_received_time,
  server_upload_time,
  session_id,
  user_creation_time,
  user_id,
  user_properties.provider_name AS user_properties_provider_name,
  user_properties.referrer AS user_properties_referrer,
  user_properties.referring_domain AS user_properties_referring_domain,
  user_properties.user_agent AS user_properties_user_agent,
  uuid,
  version_name,
FROM
  `amplitude.benefits_events`
