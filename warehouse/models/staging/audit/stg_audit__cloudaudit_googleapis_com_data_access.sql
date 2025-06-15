{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='job_type',
    )
}}
-- we should use https://cloud.google.com/bigquery/docs/reference/standard-sql/json_functions#parse_json when available

-- Note these two source CTEs use a direct reference instead of source, because a new table is created daily
WITH latest AS (
    {% set yesterday = modules.datetime.date.today() - modules.datetime.timedelta(days=1) %}

    SELECT
        -- This was previously a SELECT *, but changes to the audit logs required us to align old
        -- columns (including nested fields) with new ones in late 2023 for the 90-day lookback to
        -- work as expected. A SELECT * can likely be restored by March of 2024.
        logname,
        STRUCT(
            resource.type,
            STRUCT(
                resource.labels.dataset_id,
                resource.labels.project_id,
                resource.labels.location
            )
            AS labels
        )
        AS resource,
        STRUCT(
            protopayload_auditlog.servicename,
            protopayload_auditlog.methodname,
            protopayload_auditlog.resourcename,
            protopayload_auditlog.resourcelocation,
            protopayload_auditlog.numresponseitems,
            protopayload_auditlog.status,
            STRUCT(
                protopayload_auditlog.authenticationinfo.principalemail,
                protopayload_auditlog.authenticationinfo.authorityselector,
                protopayload_auditlog.authenticationinfo.serviceaccountkeyname,
                protopayload_auditlog.authenticationinfo.serviceaccountdelegationinfo,
                protopayload_auditlog.authenticationinfo.principalsubject
            )
            AS authenticationinfo,
            protopayload_auditlog.authorizationinfo,
            protopayload_auditlog.policyviolationinfo,
            STRUCT(
                protopayload_auditlog.requestmetadata.callerip,
                protopayload_auditlog.requestmetadata.callersupplieduseragent,
                protopayload_auditlog.requestmetadata.callernetwork,
                protopayload_auditlog.requestmetadata.requestattributes,
                protopayload_auditlog.requestmetadata.destinationattributes
            )
            AS requestmetadata,
            protopayload_auditlog.metadatajson
        )
        AS protopayload_auditlog,
        textpayload,
        timestamp,
        receivetimestamp,
        severity,
        insertid,
        httprequest,
        operation,
        trace,
        spanid,
        tracesampled,
        sourcelocation,
        split,
    FROM `{{ env_var('GOOGLE_CLOUD_PROJECT') }}`.audit.cloudaudit_googleapis_com_data_access_{{ yesterday.strftime('%Y%m%d') }}
),

everything AS ( -- noqa: ST03
    -- without this limited lookback, we'd eventually exhaust query resources on full refreshes
    -- since we might end up unioning hundreds of tables
    -- technically we have data back to 2022-04-11
    {% set days = 90 %}

    {% for day in range(days) %}

    {% set current = modules.datetime.date.today() - modules.datetime.timedelta(days=day) %}

    SELECT
        -- This was previously a SELECT *, but changes to the audit logs required us to align old
        -- columns (including nested fields) with new ones in late 2023 for the 90-day lookback to
        -- work as expected. A SELECT * can likely be restored by March of 2024.
        logname,
        STRUCT(
            resource.type,
            STRUCT(
                resource.labels.dataset_id,
                resource.labels.project_id,
                resource.labels.location
            )
            AS labels
        )
        AS resource,
        STRUCT(
            protopayload_auditlog.servicename,
            protopayload_auditlog.methodname,
            protopayload_auditlog.resourcename,
            protopayload_auditlog.resourcelocation,
            protopayload_auditlog.numresponseitems,
            protopayload_auditlog.status,
            STRUCT(
                protopayload_auditlog.authenticationinfo.principalemail,
                protopayload_auditlog.authenticationinfo.authorityselector,
                protopayload_auditlog.authenticationinfo.serviceaccountkeyname,
                protopayload_auditlog.authenticationinfo.serviceaccountdelegationinfo,
                protopayload_auditlog.authenticationinfo.principalsubject
            )
            AS authenticationinfo,
            protopayload_auditlog.authorizationinfo,
            protopayload_auditlog.policyviolationinfo,
            STRUCT(
                protopayload_auditlog.requestmetadata.callerip,
                protopayload_auditlog.requestmetadata.callersupplieduseragent,
                protopayload_auditlog.requestmetadata.callernetwork,
                protopayload_auditlog.requestmetadata.requestattributes,
                protopayload_auditlog.requestmetadata.destinationattributes
            )
            AS requestmetadata,
            protopayload_auditlog.metadatajson
        )
        AS protopayload_auditlog,
        textpayload,
        timestamp,
        receivetimestamp,
        severity,
        insertid,
        httprequest,
        operation,
        trace,
        spanid,
        tracesampled,
        sourcelocation,
        split,
    FROM `{{ env_var('GOOGLE_CLOUD_PROJECT') }}`.audit.cloudaudit_googleapis_com_data_access_{{ current.strftime('%Y%m%d') }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}

    {% endfor %}
),

data_to_process AS (
    SELECT
        *,
        EXTRACT(DATE FROM timestamp) AS date,
        -- do some initial renaming/unnesting here since we can't refer to same-SELECT aliases
        protopayload_auditlog AS payload,
        protopayload_auditlog.metadataJson AS metadata,

        JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job') AS job

    {% if is_incremental() %}
    FROM latest
    {% else %}
    FROM everything
    {% endif %}
),

stg_audit__cloudaudit_googleapis_com_data_access AS (
    SELECT
        timestamp,
        date,
        severity,
        payload.resourceName as resource_name,
        payload.authenticationInfo.principalEmail AS principal_email,
        JSON_VALUE(metadata, '$.jobChange.job.jobName') as job_name,

        JSON_VALUE(job, '$.jobConfig.type') as job_type,
        JSON_VALUE(job, '$.jobConfig.labels.dbt_invocation_id') AS dbt_invocation_id,
        JSON_VALUE(job, '$.jobConfig.queryConfig.createDisposition') AS create_disposition,
        JSON_VALUE(job, '$.jobConfig.queryConfig.destinationTable') AS destination_table,
        JSON_VALUE(job, '$.jobConfig.queryConfig.priority') AS priority,
        JSON_VALUE(job, '$.jobConfig.queryConfig.query') AS query,
        JSON_VALUE(job, '$.jobConfig.queryConfig.statementType') AS statement_type,
        JSON_VALUE(job, '$.jobConfig.queryConfig.writeDisposition') AS write_disposition,

        TIMESTAMP_DIFF(
            CAST(JSON_VALUE(job, '$.jobStats.endTime') AS timestamp),
            CAST(JSON_VALUE(job, '$.jobStats.createTime') AS timestamp),
            SECOND
        ) AS duration_in_seconds,
        JSON_VALUE_ARRAY(job, '$.jobStats.queryStats.referencedTables') as referenced_tables,
        CAST(JSON_VALUE(job, '$.jobStats.queryStats.totalBilledBytes') AS int64) AS total_billed_bytes,
        5.0 * CAST(JSON_VALUE(job, '$.jobStats.queryStats.totalBilledBytes') AS int64) / POWER(2, 40) AS estimated_cost_usd, -- $5/TB
        CAST(JSON_VALUE(job, '$.jobStats.totalSlotMs') AS int64) / 1000 AS total_slots_seconds,

        JSON_VALUE(metadata, '$.tableDataRead.jobName') as table_data_read_job_name,

        -- try to parse out the dbt node if we can
        TRIM(REGEXP_EXTRACT(JSON_VALUE(job, '$.jobConfig.queryConfig.query'), r'\/\*\s.*\s\*\/'), '/* ') AS dbt_header,
        JSON_VALUE(TRIM(REGEXP_EXTRACT(JSON_VALUE(job, '$.jobConfig.queryConfig.query'), r'\/\*\s.*\s\*\/'), '/* '), '$.node_id') AS dbt_node,

        payload,
        metadata,
        job
    FROM data_to_process

    WHERE job IS NOT NULL
)

SELECT * FROM stg_audit__cloudaudit_googleapis_com_data_access
