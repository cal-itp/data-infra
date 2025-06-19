{{ config(enabled=False) }}

WITH source AS (
    SELECT * FROM `{{ env_var('GOOGLE_CLOUD_PROJECT', var('GOOGLE_CLOUD_PROJECT')) }}`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT -- noqa
),

stg_info__jobs_by_project AS (
    SELECT
        job_id,
        project_id,
        job_type,
        priority,
        state,
        creation_time AS created_at,
        TIMESTAMP_DIFF(end_time, start_time, SECOND) AS duration_in_seconds,
        total_bytes_processed,
        total_bytes_billed,
        total_slot_ms,
        error_result IS NOT NULL AS is_error,
        error_result,
        timeline

    FROM source
)

SELECT * FROM stg_info__jobs_by_project
