{{ config(materialized='table') }}

WITH stg_transit_database__transit_data_quality_issues AS (
        {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__transit_data_quality_issues'),
        order_by = 'dt DESC'
        ) }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

dim_services AS (
    SELECT * FROM {{ ref('int_transit_database__services_dim') }}
),

dim_issue_types AS (
    SELECT * FROM {{ ref('int_transit_database__issue_types_dim') }}
),

unnested AS (
    SELECT
        id,
        description,
        gtfs_datasets[SAFE_OFFSET(0)] as gtfs_dataset_key,
        status,
        issue__,
        issue_type[SAFE_OFFSET(0)] AS issue_type_key,
        services[SAFE_OFFSET(0)] AS service_key,
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
        last_modified,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until,
        dt
    FROM stg_transit_database__transit_data_quality_issues
),

joins AS (
    SELECT
        unnested.id AS source_record_id,
        gtfs_dataset_key,
        creation_dataset.key AS gtfs_dataset_key_at_creation,
        creation_dataset.name AS gtfs_dataset_name,
        unnested.gtfs_dataset_key AS gtfs_dataset_source_record_id,
        resolution_dataset.key AS gtfs_dataset_key_at_resolution,
        creation_service.key AS service_key_at_creation,
        creation_service.name AS service_name,
        unnested.service_key AS service_source_record_id,
        resolution_service.key AS service_key_at_resolution,
        description,
        dim_issue_types.name as issue_type_name,
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
        caltrans_district__from_operating_county_geographies___from_services_,
        is_open,
        last_modified,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until
    FROM unnested
    LEFT JOIN dim_gtfs_datasets AS creation_dataset
        ON unnested.gtfs_dataset_key = creation_dataset.source_record_id
        AND unnested.issue_creation_time BETWEEN creation_dataset._valid_from AND creation_dataset._valid_to
    LEFT JOIN dim_gtfs_datasets AS resolution_dataset
        ON unnested.gtfs_dataset_key = resolution_dataset.source_record_id
        AND CAST(unnested.resolution_date AS TIMESTAMP) BETWEEN resolution_dataset._valid_from AND resolution_dataset._valid_to
    LEFT JOIN dim_services AS creation_service
        ON unnested.service_key = creation_service.source_record_id
        AND unnested.issue_creation_time BETWEEN creation_service._valid_from AND creation_service._valid_to
    LEFT JOIN dim_services AS resolution_service
        ON unnested.service_key = resolution_service.source_record_id
        AND CAST(unnested.resolution_date AS TIMESTAMP) BETWEEN resolution_service._valid_from AND resolution_service._valid_to
    LEFT JOIN dim_issue_types
        -- if either of these tables was actually historical this join would need to account for that
        ON unnested.issue_type_key = dim_issue_types.source_record_id
),

int_transit_database__transit_data_quality_issues AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['source_record_id', 'gtfs_dataset_source_record_id', 'service_source_record_id']) }} AS key,
        source_record_id,
        description,
        issue_type_name,
        gtfs_dataset_key_at_creation,
        gtfs_dataset_key_at_resolution,
        gtfs_dataset_name,
        gtfs_dataset_source_record_id,
        status,
        issue__,
        service_key_at_creation,
        service_key_at_resolution,
        service_name,
        service_source_record_id,
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
        last_modified,
        last_update_month,
        last_update_year,
        status_notes,
        waiting_since,
        outreach_status,
        should_wait_until
    FROM joins
)

SELECT * FROM int_transit_database__transit_data_quality_issues
