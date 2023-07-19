{{ config(materialized='table') }}

WITH latest_data_schemas AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__transit_data_quality_issues'),
        order_by = 'dt DESC'
        ) }}
),

historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_data_schemas
),

unnested AS (
    SELECT
        id,
        description,
        issue_type,
        gtfs_dataset,
        status,
        issue__,
        service,
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
        _is_current,
        _valid_from,
        _valid_to,
    FROM historical,
    UNNEST(gtfs_datasets) AS gtfs_dataset,
    UNNEST(services) AS service,
    UNNEST(issue_type) AS issue_type,
    UNNEST(caltrans_district__from_operating_county_geographies___from_services_) AS caltrans_district__from_operating_county_geographies___from_services_
),

int_transit_database__transit_data_quality_issues AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from', 'gtfs_dataset', 'service', 'issue_type', 'caltrans_district__from_operating_county_geographies___from_services_']) }} AS key,
        id AS source_record_id,
        description,
        issue_type,
        gtfs_dataset,
        status,
        issue__,
        service,
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
        _is_current,
        _valid_from,
        _valid_to,
    FROM unnested
)

SELECT * FROM int_transit_database__transit_data_quality_issues
