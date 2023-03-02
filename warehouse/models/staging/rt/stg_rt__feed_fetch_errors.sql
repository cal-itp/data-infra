{{
    config(
        materialized='incremental',
        unique_key='event_id',
        partitions=['current_timestamp()'],
        cluster_by='group_id',
    )
}}

WITH source AS (
    SELECT * FROM {{ source('sentry_external_tables', 'events') }}
    WHERE dt IS NOT NULL
    AND execution_ts = (
        SELECT MAX(execution_ts) FROM {{ source('sentry_external_tables', 'events') }}
        WHERE dt IS NOT NULL
        AND execution_ts IS NOT NULL
        AND project_slug IS NOT NULL)
    AND project_slug IS NOT NULL
),

stg_rt__feed_fetch_errors AS (
    SELECT
        project_id,
        timestamp,
        event_id,
        platform,
        environment,
        release,
        dist,
        ip_address_v4,
        ip_address_v6,
        user,
        user_id,
        user_name,
        user_email,
        sdk_name,
        sdk_version,
        http_method,
        http_referer,
        tags_key,
        tags_value,
        contexts_key,
        contexts_value,
        transaction_name,
        span_id,
        trace_id,
        `partition`,
        offset,
        message_timestamp,
        retention_days,
        deleted,
        group_id,
        primary_hash,
        hierarchical_hashes,
        received,
        message,
        title,
        culprit,
        level,
        location,
        version,
        type,
        exception_stacks_type,
        exception_stacks_value,
        exception_stacks_mechanism_type,
        exception_stacks_mechanism_handled,
        exception_frames_abs_path,
        exception_frames_colno,
        exception_frames_filename,
        exception_frames_function,
        exception_frames_lineno,
        exception_frames_in_app,
        exception_frames_package,
        exception_frames_module,
        exception_frames_stack_level,
        sdk_integrations,
        modules_name,
        modules_version,
        project_slug,
        dt,
        execution_ts
    FROM source
)

SELECT * FROM stg_rt__feed_fetch_errors
