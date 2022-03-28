---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.amplitude_benefits_events"

external_dependencies:
  - amplitude_benefits_loader: all

description: |
  Benefits application event data from Amplitude, via Google Cloud Services and BigQuery. See more details of data schema here https://developers.amplitude.com/docs/http-api-v2#properties-1

fields:
  app: App name
  device_id: A device-specific identifier, such as the Identifier for Vendor on iOS.
  user_id: A readable ID specified by you.
  client_event_time: TIMESTAMP
  event_id: An incrementing counter to distinguish events with the same user_id and timestamp from each other.
  session_id: The start time of the session in milliseconds since epoch (Unix Timestamp)
  event_type: The unique identifier for your event.
  amplitude_event_type: Name of Amplitude event.
  version_name: Version name.
  device_brand: The device brand that the user is using.
  device_family: The device family that the user is using.
  device_type: The device type that the user is using.
  device_carrier: The carrier that the user is using.
  location_lat: The current Latitude of the user.
  location_lng: The current Longitude of the user.
  language: The language set by the user.
  city: The current city of the user.
  event_properties: Event properties with transit provider_name, path, language
  user_properties: User properties with referring_domain, referrer, user_agent
  event_time: Event time (e.g. "2021-12-09 00:45:29.430000"),
  client_upload_time: Client upload time,
  server_upload_time: Server upload time,
  server_received_time: Server received time,
  amplitude_id: INT64,
  user_creation_time: User creation time,
  uuid: UUID,
  schema: Schema,
  processed_time: Processed time
---

SELECT * FROM `amplitude.benefits_events`
