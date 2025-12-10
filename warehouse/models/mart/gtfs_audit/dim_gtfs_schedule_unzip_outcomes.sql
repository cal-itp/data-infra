{{ config(materialized='table') }}

WITH dim_gtfs_schedule_unzip_outcomes AS (
    SELECT DISTINCT
           unzip_outcomes.dt AS dt,
           unzip_outcomes.ts AS ts,
           success,
           exception,
           zipfile_extract_md5hash,
           zipfile_files,
           zipfile_dirs,
           unnest_extracted_files.filename AS extracted_files_filename,
           unnest_extracted_files.original_filename AS extracted_files_original_filename,
           unnest_extracted_files.ts AS extracted_files_ts,
           unnest_extracted_files.extract_config.extracted_at AS extracted_files_extract_config_extracted_at,
           unnest_extracted_files.extract_config.name AS extracted_files_extract_config_name,
           unnest_extracted_files.extract_config.url AS extracted_files_extract_config_url,
           unnest_extracted_files.extract_config.feed_type AS extracted_files_extract_config_feed_type,
           unnest_extracted_files.extract_config.schedule_url_for_validation AS extracted_files_extract_config_schedule_url_for_validation,
           TO_JSON_STRING(unnest_extracted_files.extract_config.auth_query_params) AS extracted_files_extract_config_auth_query_params,
           TO_JSON_STRING(unnest_extracted_files.extract_config.auth_headers) AS extracted_files_extract_config_auth_headers,
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
      FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }} AS unzip_outcomes
     CROSS JOIN UNNEST(extracted_files) AS unnest_extracted_files
     WHERE unnest_extracted_files IS NOT NULL
)

SELECT * FROM dim_gtfs_schedule_unzip_outcomes
