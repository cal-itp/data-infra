{{ config(materialized='table') }}

WITH fct_bigquery_data_access AS (
    SELECT
        timestamp,
        date,
        severity,
        resource_name,
        principal_email,
        principal_subject,
        job_name,
        job_type,
        dbt_invocation_id,
        create_disposition,
        destination_table,
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
        payload,
        metadata,
        job
    FROM {{ ref('stg_audit__cloudaudit_googleapis_com_data_access') }}
)

SELECT * FROM fct_bigquery_data_access
