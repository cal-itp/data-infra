WITH
once_daily_transit_data_quality_issues AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_data_quality_issues__transit_data_quality_issues'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_data_quality_issues__transit_data_quality_issues AS (
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
        dt,
        ts,
    FROM once_daily_transit_data_quality_issues
)

SELECT * FROM stg_transit_data_quality_issues__transit_data_quality_issues
