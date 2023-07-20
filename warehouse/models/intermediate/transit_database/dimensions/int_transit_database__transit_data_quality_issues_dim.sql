{{ config(materialized='table') }}

WITH latest_transit_data_quality_issues AS (
    SELECT *
    FROM {{ ref('int_transit_database__transit_data_quality_issues_unnested') }}
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

historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_transit_data_quality_issues
),

join_gtfs_datasets AS (
    SELECT
        historical.id AS source_record_id,
        dim_gtfs_datasets.key AS gtfs_dataset_key,
        dim_gtfs_datasets.name AS gtfs_dataset_name,
        dim_gtfs_datasets.source_record_id AS gtfs_dataset_source_record_id,
        description,
        issue_type_key,
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
        (historical._is_current AND dim_gtfs_datasets._is_current) AS _is_current,
        GREATEST(historical._valid_from, dim_gtfs_datasets._valid_from) AS _valid_from,
        LEAST(historical._valid_to, dim_gtfs_datasets._valid_to) AS _valid_to
    FROM historical
    INNER JOIN dim_gtfs_datasets
        ON historical.gtfs_dataset_key = dim_gtfs_datasets.source_record_id
        AND historical._valid_from < dim_gtfs_datasets._valid_to
        AND historical._valid_to > dim_gtfs_datasets._valid_from
),

join_services AS (
    SELECT
        join_gtfs_datasets.source_record_id,
        dim_services.key AS service_key,
        dim_services.name AS service_name,
        dim_services.source_record_id AS service_source_record_id,
        description,
        issue_type_key,
        gtfs_dataset_key,
        status,
        issue__,
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
        (join_gtfs_datasets._is_current AND dim_services._is_current) AS _is_current,
        GREATEST(join_gtfs_datasets._valid_from, dim_services._valid_from) AS _valid_from,
        LEAST(join_gtfs_datasets._valid_to, dim_services._valid_to) AS _valid_to
    FROM join_gtfs_datasets
    INNER JOIN dim_services
        ON join_gtfs_datasets.service_key = dim_services.source_record_id
        AND join_gtfs_datasets._valid_from < dim_services._valid_to
        AND join_gtfs_datasets._valid_to > dim_services._valid_from
),

join_issue_types AS (
    SELECT
        join_services.source_record_id,
        description,
        issue_type_key,
        distinct_issue_types.name as issue_type_name,
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
        (join_services._is_current AND distinct_issue_types._is_current) AS _is_current,
        GREATEST(join_services._valid_from, distinct_issue_types._valid_from) AS _valid_from,
        LEAST(join_services._valid_to, distinct_issue_types._valid_to) AS _valid_to
    FROM join_services
    INNER JOIN (select distinct source_record_id, name, _is_current, _valid_from, _valid_to from dim_issue_types) as distinct_issue_types
        ON join_services.issue_type_key = distinct_issue_types.source_record_id
        AND join_services._valid_from < distinct_issue_types._valid_to
        AND join_services._valid_to > distinct_issue_types._valid_from
),

int_transit_database__transit_data_quality_issues_dim AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['source_record_id', '_valid_from', 'gtfs_dataset_key', 'service_key', 'issue_type_key', 'caltrans_district__from_operating_county_geographies___from_services__key']) }} AS key,
        source_record_id,
        description,
        issue_type_key,
        issue_type_name,
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
        _is_current,
        _valid_from,
        _valid_to,
    FROM join_issue_types
)

SELECT * FROM int_transit_database__transit_data_quality_issues_dim
