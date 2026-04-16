{{ config(materialized='table') }}

# For data security, do not show the bucket name or file path.

WITH dim_littlepay_sync_job_results AS (
    SELECT
        {{ trim_make_empty_string_null('instance') }} AS instance,
        {{ trim_make_empty_string_null('filename') }} AS filename,
        {{ trim_make_empty_string_null('`extract`.filename') }} AS extract_filename,
        {{ trim_make_empty_string_null('`extract`.instance') }} AS extract_instance,
        SAFE_CAST(`extract`.ts AS TIMESTAMP) AS extract_ts,
        {{ trim_make_empty_string_null('`extract`.s3object.ETag') }} AS extract_s3object_etag,
        SAFE_CAST(`extract`.s3object.LastModified AS TIMESTAMP) AS extract_s3object_last_modified,
        SAFE_CAST(`extract`.s3object.Size AS INTEGER) AS extract_s3object_size,
        {{ trim_make_empty_string_null('`extract`.s3object.StorageClass') }} AS extract_s3object_storage_class,
        SAFE_CAST(ts AS TIMESTAMP) AS ts
    FROM {{ source('external_littlepay_v3', 'littlepay_parse_job_results') }}
)

SELECT * FROM dim_littlepay_sync_job_results
