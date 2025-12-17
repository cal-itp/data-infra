{{ config(materialized='table') }}

WITH dim_gtfs_schedule_validation_outcomes AS (
    SELECT DISTINCT
           dt,
           ts,
           success,
           exception,
           validation.filename AS validation_filename,
           validation.ts AS validation_ts,
           TO_JSON_STRING(validation.system_errors) AS validation_system_errors,
           validation.validator_version AS validation_validator_version,
           validation.extract_config.extracted_at AS validation_extract_config_extracted_at,
           validation.extract_config.name AS validation_extract_config_name,
           validation.extract_config.url AS validation_extract_config_url,
           {{ to_url_safe_base64('validation.extract_config.url') }} AS validation_extract_config_base64_url,
           validation.extract_config.feed_type AS validation_extract_config_feed_type,
           validation.extract_config.schedule_url_for_validation AS validation_extract_config_schedule_url_for_validation,
           TO_JSON_STRING(validation.extract_config.auth_query_params) AS validation_extract_config_auth_query_params,
           TO_JSON_STRING(validation.extract_config.auth_headers) AS validation_extract_config_auth_headers,
           `extract`.filename AS extract_filename,
           `extract`.ts AS extract_ts,
           `extract`.response_code AS extract_response_code,
           TO_JSON_STRING(`extract`.response_headers) AS extract_response_headers,
           `extract`.reconstructed AS extract_reconstructed,
           `extract`.config.extracted_at AS extract_config_extracted_at,
           `extract`.config.name AS extract_config_name,
           `extract`.config.url AS extract_config_url,
           {{ to_url_safe_base64('`extract`.config.url') }} AS extract_config_base64_url,
           `extract`.config.feed_type AS extract_config_feed_type,
           `extract`.config.schedule_url_for_validation AS extract_config_schedule_url_for_validation,
           TO_JSON_STRING(`extract`.config.auth_query_params) AS extract_config_auth_query_params,
           TO_JSON_STRING(`extract`.config.auth_headers) AS extract_config_auth_headers
      FROM {{ source('external_gtfs_schedule', 'validations_outcomes') }}
)

SELECT * FROM dim_gtfs_schedule_validation_outcomes
