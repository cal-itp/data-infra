{{ config(materialized='table') }}

WITH dim_gtfs_download_configs AS (
    SELECT DISTINCT
           name,
           url,
           feed_type,
           schedule_url_for_validation,
           TO_JSON_STRING(auth_query_params) AS auth_query_params,
           TO_JSON_STRING(auth_headers) AS auth_headers,
           extracted_at,
           dt,
           ts
      FROM {{ source('external_gtfs_schedule', 'download_configs') }}
)

SELECT * FROM dim_gtfs_download_configs
