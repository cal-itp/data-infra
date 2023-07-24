{{ config(materialized='table') }}

WITH int_transit_database__transit_data_quality_issues_dim AS (
    SELECT * FROM {{ ref('int_transit_database__transit_data_quality_issues_dim') }}
),

dim_transit_data_quality_issues AS (
    SELECT
        key,
        source_record_id,
        description,
        issue_type_key,
        issue_type_name,
        gtfs_dataset_key_at_creation,
        gtfs_dataset_key_at_resolution,
        status,
        issue__,
        service_key_at_creation,
        service_key_at_resolution,
        resolution_date,
        assignee,
        issue_creation_time,
        waiting_over_a_week_,
        created_by,
        qc__num_services,
        qc__num_issue_types,
        qc_checks,
        waiting_on_someone_other_than_transit_data_quality_,
        is_open,
        last_update,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until,
        _is_current,
        _valid_from,
        _valid_to,
    FROM int_transit_database__transit_data_quality_issues_dim
)

SELECT * FROM dim_transit_data_quality_issues
