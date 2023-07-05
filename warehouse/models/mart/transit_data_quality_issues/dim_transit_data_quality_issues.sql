{{ config(materialized='table') }}

WITH stg_transit_data_quality_issues__transit_data_quality_issues AS (
    SELECT * FROM {{ ref('stg_transit_data_quality_issues__transit_data_quality_issues') }}
),

dim_transit_data_quality_issue_types AS (
    SELECT
        id,
        description,
        issue_type,
        gtfs_datasets,
        status,
        issue__,
        services,
        resolution_date,
        assignee,
        issue_creation_time,
        waiting_over_a_week_,
        created_by,
        qc__num_services,
        qc__num_issue_types,
        qc_checks,
        waiting_on_someone_other_than_transit_data_quality_,
        caltrans_district__from_operating_county_geographies___from_services_,
        is_open,
        last_update,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until,
    FROM stg_transit_data_quality_issues__transit_data_quality_issues
)

SELECT * FROM dim_transit_data_quality_issue_types
