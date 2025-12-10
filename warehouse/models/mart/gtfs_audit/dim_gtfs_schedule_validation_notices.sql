{{ config(materialized='table') }}

WITH dim_gtfs_schedule_validation_notices AS (
    SELECT DISTINCT
           dt,
           ts,
           base64_url,
           code,
           severity,
           totalNotices AS total_notices,
           metadata.gtfs_validator_version AS metadata_gtfs_validator_version,
           metadata.extract_config.extracted_at AS metadata_extract_config_extracted_at,
           metadata.extract_config.name AS metadata_extract_config_name,
           metadata.extract_config.url AS metadata_extract_config_url,
           metadata.extract_config.feed_type AS metadata_extract_config_feed_type,
           metadata.extract_config.schedule_url_for_validation AS metadata_extract_config_schedule_url_for_validation,
           TO_JSON_STRING(metadata.extract_config.auth_query_params) AS metadata_extract_config_auth_query_params,
           TO_JSON_STRING(metadata.extract_config.auth_headers) AS metadata_extract_config_auth_headers,
           sampleNotices AS sample_notices
      FROM {{ source('external_gtfs_schedule', 'validation_notices') }}
)

SELECT * FROM dim_gtfs_schedule_validation_notices
