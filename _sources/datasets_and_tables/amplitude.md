# Amplitude

[Amplitude](https://amplitude.com/) is used to track key user events in the [Benefits](https://github.com/cal-itp/benefits) application. Data from the Amplitude API is ingested into the `ingest_amplitude_raw_dev` and `ingest_amplitude_raw_prod` bucket, in a folder called `/benefits/`. The view makes the data available to users in Metabase.

The DAG loads events from Amplitude API to Google Cloud Storage as flattened JSON, moves JSONL to BigQuery table and moves BigQuery table to a view.

## Data Schema

| Field | description |
| ----- | ----------- |
| `amplitude_id` | ID |
| `app` | App name |
| `city` | The current city of the user |
| `client_event_time` | Client event timestamp |
| `client_upload_time` | Client upload time |
| `country` | The current country of the user |
| `device_family` | The device family that the user is using |
| `device_id` | A device-specific identifier such as the Identifier for Vendor on iOS |
| `device_type` | The device type that the user is using |
| `event_id` | An incrementing counter to distinguish events with the same user_id and  |timestamp from each other
| `event_properties_language` | Event property language - Application language |
| `event_properties_path` | Event property path - Application path |
| `event_properties_provider_name` | Event property provider name - Transit provider name |
| `event_properties_status` | Eligibility check event property status - cancel, fail or  |success
| `event_time` | Event time (e.g. "2021-12-09 00:45:29.430000") |
| `event_type` | The unique identifier for your event |
| `language` | The language set by the user |
| `processed_time` | Processed time |
| `schema` | Schema |
| `server_received_time` | Server received time |
| `server_upload_time` | Server upload time |
| `session_id` | The start time of the session in milliseconds since epoch |
| `user_creation_time` | User creation time |
| `user_id` | A readable ID specified by you |
| `user_properties_provider_name` | User property provider name |
| `user_properties_referrer` | User property preferrer |
| `user_properties_referring_domain` | User property referring domain |
| `user_properties_user_agent` | User property user agent |
| `uuid` | UUID |
| `version_name` | Version name |

See more details of data schema from the [Amplitude HTTP API V2 docs](https://developers.amplitude.com/docs/http-api-v2#properties-1).

## View Table

| dataset | description | notes |
| ------- | ----------- | -------- |
| `views.amplitude_benefits_events` | One row per event | Records go back to `2021-12-08` |
