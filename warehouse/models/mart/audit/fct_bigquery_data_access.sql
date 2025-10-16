{{ config(
    materialized='incremental',
    partition_by={
        'field': 'date',
        'data_type': 'date',
        'granularity': 'day',
    },
    on_schema_change='append_new_columns'
) }}

WITH fct_bigquery_data_access AS (
    SELECT
        timestamp,
        date,
        severity,
        resource_name,
        principal_email,
        principal_subject,
        -- Use principal_email if present, otherwise principal_subject
        COALESCE(NULLIF(principal_email, ''), principal_subject) AS email,
        job_name,
        job_type,
        dbt_invocation_id,
        create_disposition,
        destination_table,
        SPLIT(destination_table, '/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(destination_table, '/')) - 1)] AS destination_table_short_name,
        priority,
        query,
        statement_type,
        write_disposition,
        duration_in_seconds,
        referenced_tables,
        total_billed_bytes,
        estimated_cost_usd,
        total_slots_seconds,
        table_data_read_job_name,
        dbt_header,
        dbt_node,
        -- Short name from dbt_node or fallback to destination_table_short_name
        COALESCE(
            SPLIT(dbt_node, '.')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(dbt_node, '.')) - 1)],
            SPLIT(destination_table, '/')[SAFE_OFFSET(ARRAY_LENGTH(SPLIT(destination_table, '/')) - 1)]
        ) AS dbt_node_short_name,
        payload,
        metadata,
        job
    FROM {{ ref('stg_audit__cloudaudit_googleapis_com_data_access') }}
    {% if is_incremental() %}
        WHERE date > (SELECT MAX(date) FROM {{ this }})
    {% endif %}
)

SELECT * FROM fct_bigquery_data_access
