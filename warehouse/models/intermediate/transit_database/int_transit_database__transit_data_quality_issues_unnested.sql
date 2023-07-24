{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__transit_data_quality_issues'),
        order_by = 'dt DESC'
        ) }}
),

int_transit_database__transit_data_quality_issues_unnested AS (
    SELECT
        id,
        description,
        issue_type_key,
        gtfs_dataset_key,
        status,
        issue__,
        service_key,
        resolution_date,
        assignee,
        issue_creation_time,
        waiting_over_a_week_,
        created_by,
        qc__num_services,
        qc__num_issue_types,
        qc_checks,
        waiting_on_someone_other_than_transit_data_quality_,
        caltrans_district__from_operating_county_geographies___from_services__key,
        is_open,
        last_update,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until,
        dt,
        universal_first_val
    FROM latest,
    UNNEST(gtfs_datasets) AS gtfs_dataset_key,
    UNNEST(services) AS service_key,
    UNNEST(issue_type) AS issue_type_key
)

SELECT * FROM int_transit_database__transit_data_quality_issues_unnested
