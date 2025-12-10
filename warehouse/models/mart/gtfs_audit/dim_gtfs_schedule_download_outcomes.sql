{{ config(materialized='table') }}

WITH dim_gtfs_schedule_download_outcomes AS (
    SELECT DISTINCT
           dt,
           ts,
           success,
           exception,
           backfilled,
           config.extracted_at AS config_extracted_at,
           config.name AS config_name,
           config.url AS config_url,
           config.feed_type AS config_feed_type,
           config.schedule_url_for_validation AS config_schedule_url_for_validation,
           TO_JSON_STRING(config.auth_query_params) AS config_auth_query_params,
           TO_JSON_STRING(config.auth_headers) AS config_auth_headers,
           `extract`.filename AS extract_filename,
           `extract`.ts AS extract_ts,
           `extract`.response_code AS extract_response_code,
           TO_JSON_STRING(`extract`.response_headers) AS extract_response_headers,
           `extract`.reconstructed AS extract_reconstructed,
           `extract`.config.extracted_at AS extract_config_extracted_at,
           `extract`.config.name AS extract_config_name,
           `extract`.config.url AS extract_config_url,
           `extract`.config.feed_type AS extract_config_feed_type,
           `extract`.config.schedule_url_for_validation AS extract_config_schedule_url_for_validation,
           TO_JSON_STRING(`extract`.config.auth_query_params) AS extract_config_auth_query_params,
           TO_JSON_STRING(`extract`.config.auth_headers) AS extract_config_auth_headers
      FROM {{ source('external_gtfs_schedule', 'download_outcomes') }}
)

SELECT * FROM dim_gtfs_schedule_download_outcomes
